# No cross storage provider move

Moving bytes and metadata between different storages in a consistent way is not trivial. Moving bytes takes time, Making sure Metadata and Data stay in sync needs dedicated effort. That is the reason why the default drag and drop operation between storages is copy in MS Explorer, Mac Filer and Gnome nautilus. Hiding this behind a simple UI has lead to inconsistencies in the past.

Copying files by default makes transparent that files are copied and metadata, like shares, tags and comments is lost.

While implementing this in the web interface is easy, making the user experience on a synced folder of a client work well is a lot more challenging. To properly implement this we need a Proper Virtual Filesystem (or maybe multiple? One for each partition?) 

- [ ] Check if alternate data streams on NTFS are copied as well
