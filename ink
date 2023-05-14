#!/usr/bin/python3

'''
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                          \033[92mInk v0.2\033[0m                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

\033[91mExample usages\033[0m:
ink -gen        Generate a new key pair
ink -enc tar    Encrypt file(s) using keys in dir
ink -dec tar    Decrypt file(s) using keys in dir

\033[91mAvailable commands\033[0m:
\033[94mink\033[0m
    -enc    Encrypt a file or directory. The used key can be
            provided using the -key argument. If not provided,
            will attempt to fetch from the current directory.
            The output directory can be provided with -out arg.
    -dec    Same as -enc for decryption. Uses a private key
            instead.
    -gen    Generate a public/private key pair. Pathes can be
            provided using the -pub and -pvt arguments.
    -h      Display this help menu.
'''

import os
import sys
import glob
from pathlib import Path

try:
    import fast_file_encryption as ffe

except ModuleNotFoundError:
    # Install FFE
    
    intp = sys.executable
    os.system(f'{intp} -m pip install fast_file_encryption')


def parse_args(args: list[str]) -> dict[str, str]:
    '''
    Parse stdin arguments.
    '''
    
    params = {}
    for values in [param.split() for param in ' '.join(args).split('-')]:
        
        if not len(values): continue
        params['-' + values[0]] = values[1] if len(values) == 2 else True
    
    return params

def basecrypt(target: str, options: list[str], keyname: str) -> tuple[list[str], Path, str]:
    '''
    Initialise encryption or decryption.
    '''
    
    args = parse_args(options)
    key = args.get('-key')
    
    # Find key
    if key is None:
        
        files = os.listdir('.')
        
        for file in files:
            if keyname + '.pem' in file:
                key = file
                print(f'Using {keyname} key at', file)
                break
            
        if key is None:
            print('No key specified nor key file in current dir.')
            exit()
    
    key = Path(key)

    # Parse target
    # Target is magic path
    if glob.has_magic(target):
        print('Found magic in target')
        target = glob.glob(target)
    
    # Target is directory
    elif os.path.isdir(target):
        print('Target is directory')
        target = [
            target + file
            for file in os.listdir(target)
        ]
    
    # Target is single file
    else:
        print('Target is single file')
        target = [target]
    
    # Get output dir
    output = args.get('out', 'output/')
    if output[-1] not in '/\\': output += '/'
    
    # Create output if needed
    if not os.path.exists(output):
        print('Creating directory:', output)
        os.mkdir(output)

    return target, key, output

def confirm(text: str) -> None:
    '''
    Confirm an action or exit.
    '''
    
    response = input(f'{text} [Y/n] ')
    
    if response.strip().lower() == 'y':
        return
    
    exit()


match sys.argv[1:]:
    
    # Encrypt a file
    case ['-e' | '-enc', target, *options]:
        
        # Load arguments
        target, key, output = basecrypt( target, options, 'public' )
        
        # Initialise encryptor
        encryptor = ffe.Encryptor(ffe.read_public_key(key))
        
        confirm('Encrypting:\n\t* ' + '\n\t* '.join(target) + '\n')
        
        # Iterate files
        for index, filepath in enumerate(target):
            filename = os.path.basename(filepath)
            
            encryptor.copy_encrypted(source = Path(filepath),
                                     destination = Path(output + filename))
            
            print(f'[ \033[93m{index + 1}\033[0m/{len(target)} ] Encrypted \033[92m{filename}\033[0m')
    
    # Decrypt a file
    case ['-d' | '-dec', target, *options]:
        
        # Load arguments
        target, key, output = basecrypt( target, options, 'private' )
        
        # Initialise decryptor
        decryptor = ffe.Decryptor(ffe.read_private_key(key))
        
        confirm('Decrypting:\n\t* ' + '\n\t* '.join(target) + '\n')
        
        for index, filepath in enumerate(target):
            filename = os.path.basename(filepath)
            
            decryptor.copy_decrypted(source = Path(filepath),
                                     destination = Path(output + filename))

            print(f'[ \033[93m{index + 1}\033[0m/{len(target)} ] Decrypted \033[92m{filename}\033[0m')
    
    # Generate a new key pair
    case ['-g' | '-gen' | 'gen', *options]:
        
        # Load arguments
        args = parse_args(options)
        
        public = args.get('-public') or args.get('-pub', 'public.pem')
        private = args.get('-private') or args.get('-pvt', 'private.pem')
        
        ffe.save_key_pair(public_key = Path(public), private_key = Path(private))
        
        print(f'Generated key pair: \033[92m{public = }\033[0m;\033[91m {private = }\033[0m')

    # No argument specifed
    case [] | ['-h' | '--help']: print(__doc__)
    
    # Unhandled commands
    case _: print('\033[91mError: unsupported command.\033[0m')

# EOF