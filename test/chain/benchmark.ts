import * as readline from 'readline';
import * as process from 'process';
import {initLogger, ChainClient, BigNumber, ErrorCode, md5, sign, verify, addressFromSecretKey, ValueTransaction, parseCommand, initUnhandledRejection} from '../../src/client';

import {each, eachSeries} from 'async';

const program = require('commander');
const path = require('path');
let initedWatcher = false;

initUnhandledRejection(initLogger({loggerOptions: {console: true}}));

program
    .version('0.1.0')
    .option('-i, --init', 'do init')
    .option('-h, --host <ip>', 'set host ip')
    .option('-p, --port <port>', 'set port', 18089)
    .parse(process.argv);

console.log(program.host);
console.log(program.port);
let addressPath = path.join(process.cwd(), 'test/chain/address.json');
let addresses = require(addressPath).address;

async function doGetBalance(argv:any, address:string): Promise<{err: ErrorCode, value?: any}> {
    let host = argv['host'];
    let port = argv['port'];

    if (!host || !port) {
        console.error('no host');
        process.exit();
    }

    let chainClient = new ChainClient({
        host,
        port,
        logger: initLogger({loggerOptions: {console: false}})
    });

    let ret = await chainClient.view({
        method: 'getBalance',
        params: {address: address}
    });
    return ret;
}

function runTask(argv:any, cmd:string) {
    if (!argv) {
        console.error('invalid command');
        process.exit();
        return ;
    }
    let secret = argv['secret'];
    if (!secret) {
        console.error('no scret');
        process.exit();
        return ;
    }
    let address = addressFromSecretKey(secret)!;
    let host = argv['host'];
    let port = argv['port'];

    if (!host || !port) {
        console.error('no host');
        process.exit();
        return ;
    }

    let chainClient = new ChainClient({
        host,
        port,
        logger: initLogger({loggerOptions: {console: false}})
    });

    let watchingTx: string[] = [];

    if (!initedWatcher) {
        chainClient.on('tipBlock', async (tipBlock) => {
            console.log(`client onTipBlock, height ${tipBlock.number}`);
            for (let tx of watchingTx.slice()) {
                let {err, block, receipt} = await chainClient.getTransactionReceipt({tx});
                if (!err) {
                    if (receipt.returnCode !== 0) {
                        console.error(`tx:${tx} failed for ${receipt.returnCode}`);
                        watchingTx.splice(watchingTx.indexOf(tx), 1);
                    } else {
                        let confirm = tipBlock.number - block.number + 1;
                        if (confirm < 6) {
                            console.log(`tx:${tx} ${confirm} confirm`);
                        } else {
                            console.log(`tx:${tx} confirmed`);
                            watchingTx.splice(watchingTx.indexOf(tx), 1);
                        }
                    }
                }
            }
        });
        initedWatcher = true;
    }
    let runEnv = {
        getAddress: () => {
            console.log(address);
        },
        getBalance: async (_address: string) => {
            if (!_address) {
                _address = address;
            }
            let ret = await chainClient.view({
                method: 'getBalance',
                params: {address: _address}
            });
            if (ret.err) {
                console.error(`get balance failed for ${ret.err};`);
                return ;
            }
            console.log(`${_address}\`s Balance: ${ret.value!}`);
        },
        transferTo: async (to: string, amount: string, fee: string) => {
            let tx = new ValueTransaction();
            tx.method = 'transferTo',
            tx.value = new BigNumber(amount);
            tx.fee = new BigNumber(fee);
            tx.input = {to};
            let {err, nonce} = await chainClient.getNonce({address});
            if (err) {
                console.error(`transferTo failed for ${err}`);
                return ;
            }
            tx.nonce = nonce! + 1;
            tx.sign(secret);
            let sendRet = await chainClient.sendTransaction({tx});
            if (sendRet.err) {
                console.error(`transferTo failed for ${sendRet.err}`);
                return ;
            }
            console.log(`send transferTo tx: ${tx.hash}`);
            watchingTx.push(tx.hash);
        },

        register: async (_address: string, fee: string) => {
            let tx = new ValueTransaction();
            tx.method = 'register';
            tx.fee = new BigNumber(fee);
            tx.input = {address: _address};
            let {err, nonce} = await chainClient.getNonce({address});
            if (err) {
                console.error(`register failed for ${err}`);
                return ;
            }
            console.log(`=================${nonce}`);
            tx.nonce = nonce! + 1;
            tx.sign(secret);
            let sendRet = await chainClient.sendTransaction({tx});
            if (sendRet.err) {
                console.error(`register failed for ${sendRet.err}`);
                return ;
            }
            console.log(`send register tx: ${tx.hash}`);
            watchingTx.push(tx.hash);
        },

        unregister: async (_address: string, fee: string) => {
            let tx = new ValueTransaction();
            tx.method = 'unregister';
            tx.fee = new BigNumber(fee);
            let signstr = sign(Buffer.from(md5(Buffer.from(_address, 'hex')).toString('hex')), secret).toString('hex');
            tx.input = {address: _address, sign: signstr};
            let {err, nonce} = await chainClient.getNonce({address});
            if (err) {
                console.error(`unregister failed for ${err}`);
                return ;
            }
            tx.nonce = nonce! + 1;
            tx.sign(secret);
            let sendRet = await chainClient.sendTransaction({tx});
            if (sendRet.err) {
                console.error(`unregister failed for ${sendRet.err}`);
                return ;
            }
            console.log(`send unregister tx: ${tx.hash}`);
            watchingTx.push(tx.hash);
        },

        getMiners: async () => {
            let ret = await chainClient.view({
                method: 'getMiners',
                params: {}
            });
            if (ret.err) {
                console.error(`getMiners failed for ${ret.err};`);
                return ;
            }
            console.log(`${JSON.stringify(ret.value!)}`);
        },

        isMiner: async (_address: string) => {
            let ret = await chainClient.view({
                method: 'isMiner',
                params: {address: _address}
            });
            if (ret.err) {
                console.error(`isMiner failed for ${ret.err};`);
                return ;
            }
            console.log(`${ret.value!}`);
        },
    };

    function runCmd(_cmd: string) {
        let chain = runEnv;
        try {
            eval(_cmd);
        } catch (e) {
            console.error('e=' + e.message);
            throw e;
        }
    }

    runCmd(cmd);
}

let cmdList = [
    {cmd: 'chain.getBalance()', secret: undefined },
    {cmd: 'chain.getMiners()', secret: undefined },
    {cmd: 'chain.transferTo("159ueJXY2cBK78pjrsJXwhPGsWfJTJeik1", "2.5", "0.2")', secret: 'e109b61f011c9939ac51808fac542b66fcb358f69bf710f5d11eb5d1f3e82bc3' },
];

let env = {
    'secret':'e109b61f011c9939ac51808fac542b66fcb358f69bf710f5d11eb5d1f3e82bc3',
    'host': program.host,
    'port': program.port
};


let addressesManul = [
   ["1Bbruv7E4nP62ZD4cJqxiGrUD43psK5E2J","054898c1a167977bc42790a3064821a2a35a8aa53455b9b3659fb2e9562010f7"],
   ["159ueJXY2cBK78pjrsJXwhPGsWfJTJeik1","bb368892d16df7e99d2f08e84423ec416a8e4e8542871e2f02115e4915a1c098"],
   ["16ZJ7mRgkWf4bMmQFoyLkqW8eUCA5JqTHg","67091033899af84c918dd8394b4954cd79fc4da1e238c545479b7cccfbeccf0c"],
   ["1NAbrmtA3yDr2CsRMKmav8aLLyqhnjobU1","e4f3b5ff5c5725a16acd334edf4802a9c4fed7b5fd76a2845cc737418df6e5ae"],
   ["13dhmGDEuaoV7QvwbTm4gC6fx7CCRM7VkY","9832ef4c12abdee85290a5fe709f426a8081899346406e21ca70fad259b66f8e"],
   ["1NsES7YKm8ZbRE4K5LaPGKeSELVtAwzoTw","add099cc7a530f73530d94824c83f69c1a555d43c6b3d9b74ba76d2f64d4509d"],
   ["154bdF5WH3FXGo4v24F4dYwXnR8br8rc2r","6f1df947d7942faf4110595f3aad1f2670e11b81ac9c1d8ee98806d81ec5f591"],
   ["1J9MFbyg1zDrDrxp1ukw5QHkfeKfqxS9Ve","b1c1e7f1e6b88c074aaaa5c82d1b3486ce56f212064e26f1266a2a496060f58e"],
   ["1AicwR4Wmf5bEwQm4vuu8nj5BxFbLUnnU6","cec6605009b6e557984d32c458eeaa47f5a93956c1e8eff95a4589a8a532d273"],
   ["1GHzPAoYxzuT2aTwpwHx2z2rcaSo16pyUy","911625c2a6b0a43e3584784ccd837fb8629a67015adc65c707e941bef4f00477"],
   ["1PwcUmrCd6CRViD5eyCXNb2nVCfrstZaS8","de8f924648e15e4abdadf5a0ae40bbba96fde63bc7572158433d393aa0dcd896"],
   ["1L9SZu7Qrwu75mEsP683cAGYmRX1VFgwuP","bf5cabff7a619f3b368d6c52b92f1f958cd2bdad10ba0e4f60ef38a0bc35d89c"],
   ["1M4UqgkvuyaqvaxrwbKsppSDz7LvjaoEnD","ec8e9831c1b014d9078ce8e26902f8611c271d748273fcf99037d405d32d2abc"],
];

function doInit() {
    initedWatcher = true;
    addresses.forEach((item:[string]) => {
        cmdList.push({cmd: `chain.transferTo("${item[0]}", "10", "0.2")`, secret: undefined});
    });

    console.log(cmdList);
    eachSeries(cmdList, (cmd, next) => {
        if (cmd.secret) {
            env.secret = cmd.secret
        }
        runTask(env, cmd.cmd);
        setTimeout(next, 500);
    }, (err) => {
        if (err) {
            console.log('error when do Init', err);
        } else {
            console.log('done');
        }
    });
}

function doBenchMark(done:(value:any, realStart:any)=>void): void {
    addresses.forEach((item:any) => {
        cmdList.push({cmd: `chain.transferTo("1M4UqgkvuyaqvaxrwbKsppSDz7LvjaoEnD", "1", "0.01")`, secret: `${item[1]}`});
    });

    console.log(cmdList);

    let start = Date.now();
    each(cmdList, (cmd, next) => {

        if (cmd.secret) {
            env.secret = cmd.secret
        }
        runTask(env, cmd.cmd);
        setTimeout(() => {
            next();
        }, 10);
    }, (err)=> {
        if (err) {
            console.log('error is', err);
        } else {
            if (done) {
                done(start, Date.now());
            }
        }
    });
}

(async function() {
    let env = {
        'secret':'e109b61f011c9939ac51808fac542b66fcb358f69bf710f5d11eb5d1f3e82bc3',
        'host': program.host,
        'port': program.port
    };

    if (program.init){
        doInit();
    } else {
        let ret = await doGetBalance(env, "1M4UqgkvuyaqvaxrwbKsppSDz7LvjaoEnD");

        if (ret.err) {
            console.log('error when get balance', ret.err);
            process.exit(1);
        }

        console.log('value is', ret.value.toString());
        let expect = ret.value.plus(new BigNumber(addresses.length));
        console.log('expect value is', expect.toString());
        doBenchMark((start, realStart) => {
            setInterval(async () => {
                let ret = await doGetBalance(env, "1M4UqgkvuyaqvaxrwbKsppSDz7LvjaoEnD");
                if (ret.err) {
                    console.log('error get balance');
                    process.exit(1);
                }
                console.log('expect value is', expect.toString());
                console.log('balance is', ret.value.toString());
                if (ret.value.isEqualTo(expect)) {
                    console.log('success');
                    let delta = Date.now() - start;
                    console.log('delta is', delta / 1000);
                    console.log('real delta is', (Date.now() - realStart)/ 1000);
                    process.exit(0);
                }
            }, 1000);
        });
    }
})();
