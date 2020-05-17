# Quick reference

-	**Maintained by**:
	[tool-dockers](https://github.com/tool-dockers/docker-iops)

-	**Where to get help**:
	[the tool-dockers Community Slack][slack]

# Supported tags and respective `Dockerfile` links

-	[`0.1.0`, `0.1`, `latest`](https://github.com/tool-dockers/docker-iops/blob/master/Dockerfile)

# Quick reference (cont.)

-	**Where to file issues**:
	[https://github.com/tool-dockers/docker-iops/issues](https://github.com/tool-dockers/docker-iops/issues)

-	**Supported architectures**: ([more info](https://github.com/docker-library/official-images#architectures-other-than-amd64))
	[`amd64`](https://hub.docker.com/r/amd64/)

-	**Image updates**:
	[repo's PRs](https://github.com/tool-dockers/docker-iops/pulls) [repo's source directory](https://github.com/tool-dockers/docker-iops/tree/master/) ([history](https://github.com/tool-dockers/docker-iops/commits/master))

-	**Source of this description**:
	[repo's README](https://github.com/tool-dockers/docker-iops/blob/master/README.md) ([history](https://github.com/tool-dockers/docker-iops/commits/master/README.md))

# docker-iops

[![tool-dockers][logo]][website]

`docker-iops` is a IO benchmarking tool Docker containing Fio and IOPing. For more information, please see:

-	[fio documentation](https://fio.readthedocs.io/en/latest/)
-   [ioping documentation](https://manpages.debian.org/testing/ioping/ioping.1.en.html)
-	[iops Docker on GitHub](https://github.com/tool-dockers/docker-iops)

# Using the Container

We chose Alpine as a lightweight base with a reasonably small surface area for
security concerns, but with enough functionality for development, interactive
debugging, and useful health, watch, and exec scripts running under iops in the
container. The image also includes `curl` since it is so commonly used for
health checks.

iops always runs under [dumb-init](https://github.com/Yelp/dumb-init), which
handles reaping zombie processes and forwards signals on to all processes
running in the container. We also use [su-exec](https://github.com/ncopa/su-exec)
to run iops as a non-root "iops" user for better security.

The container exposes `VOLUME /iops/data`, which is a path were file I/O
benchmarks will place its persisted state. If this is bind mounted then
ownership will be changed to the iops user when the container starts.

The container has a I/O configuration directory set up at `/iops/config` and
the tool will load any configuration files placed here by binding a volume or
by composing a new image and adding files. If this is bind mounted then
ownership will be changed to the iops user when the container starts.

## Introduction

Frequently disk speed limits application performance. Relative to MEM and CPU,
disk speed (even SSDs) is not yet comparable to MEM and CPU. There are lots of
tool alternatives for measuring disk speed.

Some use `dd` (data duplicator) to measure performance, for example:

```console
dd if=/dev/zero of=test_file bs=64k count=16k conv=fdatasync
```

However, `dd` has several limitations that make it less ideal for benchmarking I/O performance.

- it performs single-threaded, sequential-writes, that may not match your workload
- it writes a small amount of data, so caching affects results
- it executes briefly, so results are inconsistent
- it doesn't support read speed tests

For disk benchmarking there are two kind of parameters that give a complete
overview: IOPS (I/O Per Second) and latency. This Docker provides better
alternatives: `Fio` and `IOPing`. This documentation provides explains
how to measure IOPS with `Fio`, and disk latency with `IOPing`. In addition
to `dd`, other tools such as `hdparm` are documented.

## Running the Docker

The sections below illustrate common running scenarios.

### Random Read/Write Performance

Run the following command:

```console
docker run --rm -v `pwd`/data:/iops/data tooldockers/iops:85f56cd \
    --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 \
    --name=test --filename=test --bs=4k --iodepth=64 --size=4G \
    --readwrite=randrw --rwmixread=75
```

This will create a 4 GB file, and perform 4KB reads and writes using a 75% / 25%
(ie 3 reads are performed for every 1 write) split within the file, with 64
operations running at a time. The 3:1 ratio is a rough approximation of your
typical database. You can change it as per your need.

### Sequential Read Performance


```console
docker run --rm -v `pwd`/data:/iops/data tooldockers/iops \
    --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 \
    --name=seq-read --filename=seq-read --bs=4k --iodepth=256 --size=100m \
    --readwrite=read --runtime=120 --time_based --numjobs=4 --group_reporting
```

In some cases you may see more consistent results if you use a job file instead of running the command directly. Use the following instructions for this approach:

1. Create a job file, `read.fio`, with the following:

    ```text
    [global]
    bs=4K
    iodepth=256
    direct=1
    ioengine=libaio
    group_reporting
    time_based
    runtime=120
    numjobs=4
    name=seq-read
    size=4g
    rw=read

    [job1]
    filename=device name
    ```

2. Run the job using the following command:

    ```console
    docker run --rm --privileged -v `pwd`/data:/iops/data -v `pwd`/read.fio:/iops/data/read.fio tooldockers/iops fio read.fio
    ```

### Random Read Performance

Run the below command to test random read performance.

```console
docker run --rm -v `pwd`/data:/iops/data tooldockers/iops \
    --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 \
    --name=rand-read --filename=test --bs=4k --iodepth=64 --size=4G \
    –readwrite=randread
```

### Random Write Performance

Run the below command to test random write performance.

```console
docker run --rm -v `pwd`/data:/iops/data tooldockers/iops \
    --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 \
    --name=test --filename=test --bs=4k --iodepth=64 --size=4G \
    –readwrite=randwrite
```

## IO Latency on Individual Requests

We will be using IOPing to measure the latency on individual request.

Run the below command to measure IO latency using IOPing.

```console
docker run --rm -v `pwd`/data:/iops/data tooldockers/iops ioping -c 10 /iops/data
```

The -c 10 option is the number request IOPing will make. The program takes
also as argument the file and/or device to check. In this case, the actual
working directory. Program output is:

```console
setting ownership
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=1 time=318.6 us (warmup)
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=2 time=1.56 ms
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=3 time=1.04 ms
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=4 time=1.11 ms
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=5 time=1.37 ms
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=6 time=1.13 ms
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=7 time=958.1 us (fast)
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=8 time=1.12 ms
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=9 time=1.22 ms
4 KiB <<< /iops/data (fuse.osxfs osxfs): request=10 time=1.21 ms

--- /iops/data (fuse.osxfs osxfs) ioping statistics ---
9 requests completed in 10.7 ms, 36 KiB read, 839 iops, 3.28 MiB/s
generated 10 requests in 9.01 s, 40 KiB, 1 iops, 4.44 KiB/s
min/avg/max/mdev = 958.1 us / 1.19 ms / 1.56 ms / 170.2 us
```

## HDPARM

[`hdparm`](http://man7.org/linux/man-pages/man8/hdparm.8.html) is
a command line tool to get/set SATA/IDE device parameters. It can
also be used to perform basic performance testing of buffered and
cached reads.

### Get Drive Geometry

To get the drive geometry:

```console
docker run -it --privileged --rm tooldockers/iops hdparm -g /dev/sda
```

### Short Read Test (hdparm)

To perform a short test of buffered and cached reads:

```console
docker run -it --privileged --rm tooldockers/iops hdparm -tT /dev/sda
```

# License

View [license information](https://raw.githubusercontent.com/tool-dockers/docker-iops/master/LICENSE) for the software contained in this image.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

## License

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

## About

[tool-dockers][website] maintains and funds this project.

  [logo]: https://avatars3.githubusercontent.com/u/57697117?s=60&v=4
  [website]: https://continuul.solutions
  [slack]: https://continuul.slack.com

  [oracle-fio]: https://docs.cloud.oracle.com/en-us/iaas/Content/Block/References/samplefiocommandslinux.htm
  [using-dd]: https://www.cyberciti.biz/faq/howto-linux-unix-test-disk-performance-with-dd-command/
  [shellhacks]: https://www.shellhacks.com/disk-speed-test-read-write-hdd-ssd-perfomance-linux/
