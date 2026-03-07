#!/usr/bin/env python3
"""Convert a MySQL dump (mysqldump format) to PostgreSQL-compatible SQL.

Handles:
  - Removing MySQL-specific syntax (backticks, /*!...*/, LOCK/UNLOCK, etc.)
  - Converting INSERT statements to PostgreSQL syntax
  - Converting MySQL hex BLOB (0xFF...) to PostgreSQL bytea ('\\x...')
  - Converting MySQL backslash-escaped strings to PostgreSQL dollar-quoted or
    standard escaped strings
  - Dropping CREATE TABLE / DROP TABLE (we use 0_schema.sql instead)
  - Streaming line-by-line for memory efficiency

Usage:
    python3 convert_dump.py dump.sql 1_data.sql
"""

import re
import sys


# MySQL 0xHEX... blob literal → PostgreSQL bytea hex literal
_HEX_BLOB_RE = re.compile(rb"0x([0-9A-Fa-f]+)")

# MySQL backslash escapes inside single-quoted strings
_MYSQL_ESCAPES = {
    ord("\\"): b"\\\\",
    ord("'"): b"''",      # double the quote for PostgreSQL
    ord('"'): b'"',
    ord("n"): b"\n",
    ord("r"): b"\r",
    ord("0"): b"\x00",
    ord("Z"): b"\x1a",
}


def _convert_mysql_string(m: re.Match) -> bytes:
    """Convert a MySQL single-quoted, backslash-escaped string to a
    PostgreSQL E'...' escaped string."""
    raw = m.group(1)
    out = bytearray()
    i = 0
    while i < len(raw):
        b = raw[i]
        if b == ord("\\") and i + 1 < len(raw):
            nxt = raw[i + 1]
            if nxt == ord("'"):
                out.extend(b"''")
            elif nxt == ord("\\"):
                out.extend(b"\\\\")
            elif nxt == ord('"'):
                out.extend(b'"')
            elif nxt == ord("n"):
                out.extend(b"\\n")
            elif nxt == ord("r"):
                out.extend(b"\\r")
            elif nxt == ord("0"):
                out.extend(b"\\x00")
            elif nxt == ord("Z"):
                out.extend(b"\\x1a")
            else:
                out.append(nxt)
            i += 2
        elif b == ord("'"):
            # Should not happen inside a properly escaped string,
            # but handle doubles just in case
            out.extend(b"''")
            i += 1
        else:
            out.append(b)
            i += 1
    return b"E'" + bytes(out) + b"'"


# Match a MySQL single-quoted string (handling backslash escapes)
_MYSQL_STR_RE = re.compile(rb"'((?:[^'\\]|\\.)*)'")


def convert_insert_line(line: bytes) -> bytes:
    """Convert a MySQL INSERT line to PostgreSQL format."""
    # Remove backticks
    line = line.replace(b"`", b"")

    # Convert 0xHEX blob literals to PostgreSQL '\\xHEX' bytea
    line = _HEX_BLOB_RE.sub(lambda m: b"'\\\\x" + m.group(1) + b"'", line)

    # Convert MySQL backslash-escaped strings to PostgreSQL E'' strings
    line = _MYSQL_STR_RE.sub(_convert_mysql_string, line)

    return line


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 convert_dump.py <input.sql> <output.sql>", file=sys.stderr)
        sys.exit(1)

    infile = sys.argv[1]
    outfile = sys.argv[2]

    in_create = False

    with open(infile, "rb") as fin, open(outfile, "wb") as fout:
        for raw_line in fin:
            line = raw_line.rstrip(b"\r\n")
            text = line.strip()

            # Skip MySQL directives /*!...*/
            if text.startswith(b"/*!") or text.startswith(b"*/;"):
                continue

            # Skip LOCK / UNLOCK
            if text.startswith(b"LOCK TABLES") or text.startswith(b"UNLOCK TABLES"):
                continue

            # Skip USE
            if text.startswith(b"USE "):
                continue

            # Skip SET
            if text.startswith(b"SET "):
                continue

            # Skip CREATE TABLE blocks (schema in 0_schema.sql)
            if text.startswith(b"CREATE TABLE"):
                in_create = True
                continue
            if in_create:
                if text.endswith(b";"):
                    in_create = False
                continue

            # Skip DROP TABLE
            if text.startswith(b"DROP TABLE"):
                continue

            # Skip CREATE DATABASE
            if text.startswith(b"CREATE DATABASE"):
                continue

            # Skip comments
            if text.startswith(b"--"):
                continue

            # Skip empty lines
            if not text:
                continue

            # Convert INSERT lines
            if text.startswith(b"INSERT INTO"):
                converted = convert_insert_line(line)
                fout.write(converted)
                fout.write(b"\n")
                continue

            # Pass through other lines
            fout.write(line)
            fout.write(b"\n")

    print(f"Conversion complete: {outfile}", file=sys.stderr)


if __name__ == "__main__":
    main()
