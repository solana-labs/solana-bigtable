# Setting up a Solana Bigtable Instance

 1. [Introduction](#solana-bigtable)
 2. [Requirements](#requirements)
 2. [Setting up a Warehouse node](#setting-up-a-warehouse-node)
 2. [Setting up a Google Cloud Bigtable instance](#setting-up-a-google-cloud-bigtable-instance)
 2. [Import Solana's Bigtable Instance](#import-solana's-bigtable-instance)
 2. [Requirements](#requirements)

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
Here you'll find all the necessary scripts to run your own Warehouse node:

1. `warehouse.sh` → Startup script for the Warehouse node:
    * `ledger_dir=<path_to_your_ledger>`
    * `ledger_snapshots_dir=<path_to_your_ledger_snapshots>`
    * `identity_keypair=<path_to_your_identity_keypair>`
2. `warehouse-upload-to-storage-bucket.sh` → Script to upload the hourly snapshots to Google Cloud Storage every epoch.
3. `service-env.sh` → Source file for `warehouse.sh`.
    * `GOOGLE_APPLICATION_CREDENTIALS=<path_to_your_google_cloud_credentials>`
4. `service-env-warehouse.sh` → Source file for `warehouse-upload-to-storage-bucket.sh`.
    * `ZONE=<availability_zone>`
    * `STORAGE_BUCKET=<cloud_storage_bucket_name>`

## Setting up a Google Cloud Bigtable instance

In order to import Solana's Bigtable Instance, you'll first need to set own Bigtable instance:

1. Enable the `BigTable API` if not already, then click on the `Create Instance` inside the `Console`.
2. Name your `Instance` and then Select Storage type from HDD and SSD (SSD recommended).
3. Select a location → Region → Zone.
4. Choose the number of `Nodes` for the cluster, each node provides 8TB of storage (as of 09/12/21 at least 4 nodes are required).
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
