# IEDB-in-a-Box

IEDB-in-a-box allows you to manipulate Immune Epitope Database (IEDB) public data on your own computer in a local PostgreSQL instance. Within this instance you may access either the raw data (populated using the snapshot available via the [Immune Epitope Database and Analysis Resource page](http://www.iedb.org/downloader.php?file_name=doc/iedb_public.sql.gz) (i.e. the `upstream` schema), or a logically streamlined subset of the same data (the `core`, `classes`, and `joined` schemas).

For more information on how the `upstream` schema is mapped to `core`, see [this google sheet](https://docs.google.com/spreadsheets/d/10updSttzfhsqLD-fT5Fw2zWZJt9dqQBiNVothW4lALk).


## Installation

1. Make sure you have the correct Vagrant plugins installed:

    `vagrant plugin install vagrant-vbguest`
    `vagrant vbguest`

1. Clone the repository to a local folder on your computer. For example, using the SSH method:

    `git clone git@github.com:jamesaoverton/IEDB-in-a-Box.git`

    _Note:_ the remaining steps below should all be done relative to the local directory that you just cloned to.

1. After cloning the repository, set up a virtual machine using vagrant:

    `cd tools/`  
    `vagrant up`

    The first time you run `vagrant up` it will take a while (30 minutes or more), as the virtual machine must be created, the OS and needed packages must be installed, the MariaDB and PostgreSQL instance must be configured, and the pgloader tool (which is needed to transfer data between MariaDB and PostgreSQL) must be built from source.

    Once the virtual machine is created and provisioned, you can manipulate it as follows:  
    * Shut down the VM:  
      `vagrant halt` 

    * Boot up the VM:  
      `vagrant up`

    * ssh into the VM:  
      `vagrant ssh`
    

1. Now make sure you are in the `tools/` directory, and ssh into the virtual machine:

    `vagrant ssh`

    _Note:_ The remaining steps below need to be performed from within the virtual machine:

1. Change directory to the folder that is shared between the virtual machine and the host:

    `cd /var/iedb`

1. Fetch the IEDB snapshot and load it into your MariaDB instance:

    `make rdump restore_upstream_maria`

1. Transfer the upstream database from MariaDB to your PostgreSQL instance using the pgloader tool:

    `make restore_upstream_postgres`

1. Populate the `core`, `classes`, and `joined` schemas:

    `make populate_postgres`

    *Note* that if the prcess gets stuck at the step: 'Creating temporary table tcell_host ...' for more than a minute or two, hit Ctrl-C and then re-run `make populate_postgres`

    I am not sure why it gets stuck at that step.
