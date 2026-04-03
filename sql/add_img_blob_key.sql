-- Add img_blob_key column to posts table for Azure Blob Storage integration
ALTER TABLE posts ADD COLUMN IF NOT EXISTS img_blob_key text;
