
import * as process from 'process';
import { LoggerInstance } from 'winston';

export function init(logger: LoggerInstance) {
    process.on('unhandledRejection', (reason, p) => {
        process.exit(-1);
    });
    
    process.on('uncaughtException', (err) => {
        process.exit(-1);
    });    
}
