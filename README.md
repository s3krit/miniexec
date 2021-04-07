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

# Motivation

Writing jobs for Gitlab CI can be a frustrating experience. Having to write a
job, push your change, wait for N steps in the pipeline to complete only to
attempt to run your job and tell you that you forgot a particular environment
variable... we've all been there.

Gitlab's own CI runner 'gitlab-runner' offers a function called 'gitlab-runner
exec', which will attempt to run a particular CI job locally. It works ok, but
doesn't support advanced YAML features like anchors correctly, and `exec`
generally isn't actively developed by Gitlab.

In comes miniexec - a simple parser and executor for `.gitlab-ci.yml` files.
Using `miniexec`, you can write Gitlab CI jobs and quickly test them on your
local machine.

# Installation

`miniexec` is available on [RubyGems](https://rubygems.org/gems/miniexec) and
can be installed like so:

```
gem install miniexec
```

Alternatively, clone this repository and build it yourself:

```
git clone https://github.com/s3krit/miniexec
gem build miniexec.gemspec
gem install miniexec-*.gem
```

# Basic usage

In the directory of a project that has a `.gitlab-ci.yml` file, simply call
`miniexec` like so (the following examples can all be run directly from this
repository):

```
miniexec -j miniexec-example-1
```

`miniexec` will then attempt to spawn a Docker container using the image
specified for that job (or the global image), and execute the steps in that job.

It's likely that you *also* want to pass the contents of your current directory
to some location inside that container. In the next example, we'll do exactly
that. We'll mount the current working directory to the `/build` directory and
cat README.md (the file you're reading right now!)

```
miniexec -j miniexec-example-2 -b $PWD:/build
```

You'll also likely want to pass certain environment variables to `miniexec`,
such as API keys or configuration arguments. With `miniexec`, just specify each
one with a `-e` flag, just like Docker!

```
miniexec -j miniexec-example-3 -e MY_USER=$USER -e MY_KEY=c3r34l-k1ll4h
```

# What works

- Specifying and running a job from a `.gitlab-ci.yml` file
- YAML anchors and other fancy features
- Podman! If you run podman with a user socket, simply specify the location of
    the socket with `-d` or the `DOCKER_HOST` environment variable
- Mocking of Gitlab's [predefined environment variables](https://gitlab.parity.io/help/ci/variables/predefined_variables.md) as best I can, so some of the Git stuff. This needs to be expanded.

# What doesn't

- MiniExec currently makes the assumption that the job is a shell-script and that `/bin/bash` is present.
- Sometimes the first couple lines of output in a job will be skipped
- Advanced Gitlab CI features like services
- Running full pipelines
- Probably some other stuff. If you find one, make an issue, I'd love to fix it.
- Specifying your environment variables with a file instead of one-by-one (soon™)
