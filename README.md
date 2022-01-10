# Setting up a Solana Bigtable Instance

 1. [Introduction](#solana-bigtable)
 2. [Requirements](#requirements)
 2. [Setting up a Warehouse node](#setting-up-a-warehouse-node)
 2. [Setting up a Google Cloud Bigtable instance](#setting-up-a-google-cloud-bigtable-instance)
 2. [Import Solana's Bigtable Instance](#import-solana's-bigtable-instance)
 2. [Requirements](#requirements)
 2. [Restoring Missing Blocks](#restoring-missing-blocks)

## Solana Bigtable

By design an RPC node with a default `--limit-ledger-size` will store roughly 2 epochs worth of data so Solana relies on Google Cloud's Bigtable for long term storage.
The public endpoint that Solana provides https://api.mainnet-beta.solana.com has configured its own Bigtable instance to server requests since the Genesis Block.
This guide is meant to allow anyone to run his own Bigtable instance for long term storage in the Solana Blockchain.

## Requirements

1. A Warehouse node
2. A Google Cloud Bigtable instance
3. A Google Cloud Storage bucket (optional)

## Setting up a Warehouse node

A Warehouse node is responsible for feeding Bigtable with ledger data, so setting up one is the first thing that needs to be done in order for you to have your own Solana Bigtable instance.
Structurally a Warehouse node is similar to an RPC node that doesn't server RPC calls, but instead uploads ledger data to Bigtable.
Keeping your ledger history consistent is very important on a Warehouse node, since any gap on your local ledger will translate to a gap on your Bigtable instance, although these gaps could be potentially patched up by using `solana-ledger-tool`.
Here you'll find all the necessary scripts to run your own Warehouse node.

What different scripts do:
1. `warehouse.sh` → Startup script for the Warehouse node:
2. `warehouse-upload-to-storage-bucket.sh` → Script to upload the hourly snapshots to Google Cloud Storage every epoch.
3. `service-env.sh` → Source file for `warehouse.sh`.
4. `service-env-warehouse.sh` → Source file for `warehouse-upload-to-storage-bucket.sh`.
5. `warehouse-basic.sh` → Simplified command to start the warehouse node. Run this *instead* of `warehouse.sh`.

Before you begin:
1. [Install solana-cli](https://docs.solana.com/cli/install-solana-cli-tools)
2. [Install gcloud sdk](https://cloud.google.com/sdk/docs/install)
3. [Create a gcloud service account](https://cloud.google.com/iam/docs/creating-managing-service-account-keys).
    * When creating the account give it the `Bigtable User` role.
    * You will get back a file with a name similar to `play-gcp-329606-cccf2690b876.json`. This is the file you'll have to point the `GOOGLE_APPLICATION_CREDENTIALS` variable at (below).
    * Needless to say keep the file private and don't commit to github.
4. [Tune your system](https://docs.solana.com/running-validator/validator-start#system-tuning) 

To start the validator:
1. Fill in the missing variables (eg `<path_to_your_ledger>`) inside the below files. Hint: CTRL-F for "`<`" to find all quickly.
    * `warehouse.sh`
    * `service-env.sh`
    * `service-env-warehouse.sh`
2. If it's the first time you're running a validator, you can leave `ledger_dir` and `ledger_snapshots_dir` blank. This will tell the node to fetch genesis & the latest snapshot from the cluster. 
2. `chmod +x` the following files:
    * `warehouse.sh`
    * `metrics-write-dashboard.sh`
4. Update the `EXPECTED_SHRED_VERSION` in `service-env.sh` to the appropriate version.
5. `./warehouse.sh`

To upload to bigtable:
1. Fill in the missing variables inside `<...>` in `warehouse-upload-to-storage-bucket.sh`.
2. `chmod +x warehouse-upload-to-storage-bucket.sh`
3. `./warehouse-upload-to-storage-bucket.sh`

To run as a continuous process as `systemctl`:
1. Update the user in both `.service` files (currently set to `sol`).
2. Fill in the missing variables inside `<...>` in both `.service` files.
3. `cp` both files into `/etc/systemd/system`
4. `sudo systemctl enable --now warehouse-upload-to-storage-bucket && sudo systemctl enable --now warehouse`

## Setting up a Google Cloud Bigtable instance

In order to import Solana's Bigtable Instance, you'll first need to set own Bigtable instance:

1. Enable the `BigTable API` if you have not done it already, then click on the `Create Instance` inside the `Console`.
2. Name your `Instance` and then Select Storage type from HDD and SSD. Set the instance id and name to `solana-ledger`.
3. Select a location → Region → Zone.
4. Choose the number of `Nodes` for the cluster, each node provides 16TB of storage for HDD nodes (as of 09/12/21 at least 4 HDD nodes are required).
5. Create the following tables with the respective column family names:

| Table ID   | Column Family Name |
| :--------- | :----------------: |
| blocks     | x                  |
| tx         | x                  |
| tx-by-addr | x                  |

6. It's very important to give the same `Table ID` and `Column Family Name` inside your Bigtable instance or the Dataflow job will fail.

Alternatively, you create the tables by running the following commands through CLI:

1. Update the `.cbtrc` file with credentials of the project and Bigtable instance in which we want to do the read and write operations:
    * `echo project = [PROJECT ID] > ~/.cbtrc`
    * `echo instance = [BIGTABLE INSTANCE ID] >> ~/.cbtrc`
    * `cat ~/.cbtr`
2. Create the tables inside the Bigtable instance with the family name defined inside it:
    * `cbt createtable [TABLE NAME] “families=[COLUMN FAMILY1]`
3. When creating the table inside the instance remember the transfer through Dataflow always occurs within tables having the same column family name otherwise it will throw an error like “Requested column family not found = 1”.

## Import Solana's Bigtable Instance

Once your Warehouse node has stored ledger data for 1 epoch successfully and you have set up your Bigtable instance as explained above, you are ready to import Solana's Bigtable to yours.
The import process is done through a Dataflow template that allows importing [Cloud Storage SequenceFile to Bigtable](https://cloud.google.com/dataflow/docs/guides/templates/provided-batch#expandable-11):
1. Create a new `Service Account`.
2. Assign a `Service Account Admin` role to it.
3. Enabling the `Dataflow API` in the project.
4. Create the Dataflow job from template `SequenceFile Files on Cloud storage to Cloud BigTable`.
5. Fill the `Required parameters`.

NOTE: As for now the migration process is on demand, so before creating the Dataflow job you'll need to send and email with the service account credentials you created `xxx@xxx.iam.gserviceaccount.com` to joe@solana.com or axl@solana.com.

## Restoring Missing Blocks
Sometimes blocks are missing from BigTable. This will be apparent on Explorer where the parent slot & child slot links won't form cycles. For example, before 59437028 was restored 59437027 incorrectly listed 59437029 as a child:

* https://explorer.solana.com/block/59437029: parent is 59437028
* https://explorer.solana.com/block/59437028: missing
* https://explorer.solana.com/block/59437027: child is 59437029

The missing blocks can be restored from GCS as follows:

1. Download appropriate ledger data [from GCS](https://console.cloud.google.com/storage/browser?forceOnBucketsSortingFiltering=false&project=mainnet-beta&prefix=&forceOnObjectsSortingFiltering=false)
    * Not all the region buckets have all the data, but [us-ny5](https://console.cloud.google.com/storage/browser/mainnet-beta-ledger-us-ny5;tab=objects?forceOnBucketsSortingFiltering=false&project=mainnet-beta&prefix=&forceOnObjectsSortingFiltering=false) is a good starting point
    * Find the bucket with the largest slot number that is smaller than the missing block. For example block 59437028 is in [59183944](https://console.cloud.google.com/storage/browser/mainnet-beta-ledger-us-ny5/59183944?project=mainnet-beta&pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&prefix=&forceOnObjectsSortingFiltering=false)
    * Download rocksdb.tar.bz2:
      * `~/missingBlocks/59183944$ wget https://storage.googleapis.com/mainnet-beta-ledger-us-ny5/59183944/rocksdb.tar.bz2`
    * Also note the version number in version.txt:
      * `curl https://storage.googleapis.com/mainnet-beta-ledger-us-ny5/59183944/version.txt`
        * `solana-ledger-tool 1.4.21 (src:50ebc3f4; feat:2221549166)`
2. Extract the data
    * `~/missingBlocks/59183944$ tar -I lbzip2 -xf rocksdb.tar.bz2`
        * This can take a while so use a screen session if your connection is unstable.
3. Build the ledger tool from the version listed in version.txt
    * `~/solana$ git checkout 50ebc3f4` (can also checkout v1.4.21)
    * `~/solana$ cd ledger-tool && ../cargo build --release`
        * The cargo script in the solana repo uses the rust version associated with the release to solve backwards compatibility problems.
4. Check blocks
    * `~/missingBlocks/59183944$ ~/solana/target/release/solana-ledger-tool slot 59437028 -l . | head -n 2`
        * Output should include correct parent & child. If you get a SlotNotRooted error see below.
5. Upload missing block(s) to big table
    * `~/missingBlocks/59183944$ GOOGLE_APPLICATION_CREDENTIALS=<json credentials file with write permission> ~/solana/target/release/solana-ledger-tool bigtable upload 59437028 59437028 -l .`
        * Specify two blocks to upload a range. Earlier block (smaller number) first.
        * `-l` should specify a directory that contains the rocksdb directory.
6. If the previous steps produced a `SlotNotRooted` error, first run the repair-roots command.
    * `~/missingBlocks/59183944$ ~/github/solana/target/release/solana-ledger-tool repair-roots --before 59437027 --until 59437029  -l .`
        * If you get `error: Found argument 'repair-roots' which wasn't expected, or isn't valid in this context` then the ledger tool version pre-dates the repair-roots command. Add it to your local code by cherry picking `ddfbae2` or manually applying the changes from [PR #17045](https://github.com/solana-labs/solana/pull/17045/files)
