.PHONY: init
init: sql/1_data.sql benchmarker/userdata/img

sql/dump.sql.bz2:
	cd sql && \
	curl -L -O https://github.com/catatsuy/private-isu/releases/download/img/dump.sql.bz2

sql/1_data.sql: sql/dump.sql.bz2
	cd sql && \
	bunzip2 -k -f dump.sql.bz2 && \
	python3 convert_dump.py dump.sql 1_data.sql && \
	rm -f dump.sql

benchmarker/userdata/img.zip:
	cd benchmarker/userdata && \
	curl -L -O https://github.com/catatsuy/private-isu/releases/download/img/img.zip

benchmarker/userdata/img: benchmarker/userdata/img.zip
	cd benchmarker/userdata && \
	unzip -qq -o img.zip
