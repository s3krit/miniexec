# miniexec
A minimal interpretor/executor for .gitlab-ci.yml files

```
Usage: miniexec.rb [options]

specific options:
    -p, --path PATH                  Path to the repository containing a valid .gitlab-ci.yml
    -j, --job JOBNAME                Specify the gitlab job to run
    -b, --bind BIND                  Specify a bind mapping
                                     Example: /some/local/dir:/mapping/in/container
    -e, --environment VARIABLE       Specify an environment variable to be passed to the container
                                     Example: SOMEVAR=thing
```

# TODO
- [ ] Fake Gitlab's auto-generated environment variables
- [ ] Pass the run context without needing to specify an additional volume
- [ ] Try to hook the image-pulling to print output
- [ ] Shell detection? (at the moment, we just assume all image shells are /bin/bash...)
