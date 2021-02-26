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
