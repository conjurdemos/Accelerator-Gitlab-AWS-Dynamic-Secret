# Contributing

For general contribution and community guidelines, please see the
[community repo](https://github.com/cyberark/community).

## Prerequisites

1. [git](https://git-scm.com/downloads) to manage source code
2. [Docker](https://docs.docker.com/engine/installation) to manage dependencies
   and runtime environments
3. [Go 1.22.2+](https://go.dev/doc/install) installed

## Testing

This project includes end-to-end tests that validate the Conjur and External
Secrets Operator integration through both API key and JWT authentication, in
GKE and Openshift.

To run these tests, uncomment the proper section of `demo-vars.sh`, and run:

```sh
./bin/start
```

## Pull Request Workflow

1. [Fork the project](https://help.github.com/en/github/getting-started-with-github/fork-a-repo)
2. [Clone your fork](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)
3. Make local changes to your fork by editing files
4. [Commit your changes](https://help.github.com/en/github/managing-files-in-a-repository/adding-a-file-to-a-repository-using-the-command-line)
5. [Push your local changes to the remote server](https://help.github.com/en/github/using-git/pushing-commits-to-a-remote-repository)
6. [Create new Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)

From here your pull request will be reviewed and once you've responded to all
feedback it will be merged into the project. Congratulations, you're a
contributor!

## Releases

This project does not use releases.

### Internal Contributors

To push the latest changes in the internal repository to the public one, run the
Jenkins pipeline with the "PROMOTE" build type and the "COPY_ENTERPRISE_COMMIT"
parameter set to "true".
