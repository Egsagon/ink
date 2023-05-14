# ink
CLI for encrypting and decrypting files using FFE


### Usage

Example usages:

`ink -gen`        Generate a new key pair

`ink -enc tar`    Encrypt file(s) using keys in dir

`ink -dec tar`    Decrypt file(s) using keys in dir

Available commands:

`-enc`    Encrypt a file or directory. The used key can be provided using the -key argument. If not provided, will attempt to fetch from the current directory. The output directory can be provided with -out arg.
            
`-dec`    Same as -enc for decryption. Uses a private key instead.
            
`-gen`    Generate a public/private key pair. Pathes can be provided using the -pub and -pvt arguments.
            
`-h`      Display this help menu.
