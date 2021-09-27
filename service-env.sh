#RESTART=1 # Update the below block before uncommenting this line
if [[ -n "$RESTART" ]]; then
        WAIT_FOR_SUPERMAJORITY=53180900
        EXPECTED_BANK_HASH=Fi4p8z3AkfsuGXZzQ4TD28N8QDNSWC7ccqAqTs2GPdPu
fi
EXPECTED_SHRED_VERSION=13490
EXPECTED_GENESIS_HASH=5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d
TRUSTED_VALIDATOR_PUBKEYS=(7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S)
export SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password
PATH=<your_solana_bin_path>
#MINIMUM_MINUTES_BETWEEN_ARCHIVE=720
RPC_URL=https://api.mainnet-beta.solana.com
ENTRYPOINT_HOST=mainnet-beta.solana.com
ENTRYPOINT_PORT=8001
ENTRYPOINT=mainnet-beta.solana.com:8001
ENTRYPOINTS=(
  entrypoint2.mainnet-beta.solana.com:8001
  entrypoint3.mainnet-beta.solana.com:8001
  entrypoint4.mainnet-beta.solana.com:8001
  entrypoint5.mainnet-beta.solana.com:8001
)
export RUST_BACKTRACE=1
export GOOGLE_APPLICATION_CREDENTIALS=<path_to_your_google_cloud_credentials>
ENABLE_BPF_JIT=1
ENABLE_CPI_AND_LOG_STORAGE=1
