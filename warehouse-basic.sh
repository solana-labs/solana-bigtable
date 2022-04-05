export PATH=<path-to-bins>
export GOOGLE_APPLICATION_CREDENTIALS=<path-to-bt-write-key>
export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"

solana-validator \
        --ledger <path-to-ledger> \
        --identity <path-to-key> \
        --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
        --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
        --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
        --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
        --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
        --trusted-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
        --trusted-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
        --trusted-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
        --trusted-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
        --dynamic-port-range 8000-8010 \
        --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
        --gossip-port 8001 \
        --enable-rpc-transaction-history \
        --rpc-port 8899 \
        --private-rpc \
        --log <path-to-your-logs> \
        --no-voting \
        --no-untrusted-rpc \
        --wal-recovery-mode skip_any_corrupted_record \
        --limit-ledger-size \
        --enable-bigtable-ledger-upload \
        --bpf-jit \
        --enable-cpi-and-log-storage \
        --accounts <path-to-accounts> \
        --no-genesis-fetch \
        --no-snapshot-fetch
