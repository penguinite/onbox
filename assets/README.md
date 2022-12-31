# static

Static assets for Pothole, these will be embedded into the program.

Assets are not automatically included, if they are automatically included then people will simply put in whatever inside Pothole and not watch or monitor its use or the binary size of Pothole.

I tried to create a way for me to store data inside a Nim proc, so we can store the static files in the disk instead of storing them in memory.

# Adding assets

To add an asset, simply put it here and edit src/assets.nim so its available to Nim modules that import it.

## Note

Folders are permitted for storing instance-wide themes but user blogs and user themes should be stored in the `blogs/` directory 