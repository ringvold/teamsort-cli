#!/usr/bin/env node

import { Elm } from '../build/Main.js';
import * as readline from 'readline';
import * as fs from 'fs';
import minizinc from './minizinc';

require('dotenv').config();

const globalAny: any = global;
globalAny.XMLHttpRequest = require('xhr2');

const fsPromise = fs.promises;

const program = Elm.Main.init({
    flags: {
        argv: process.argv,
        versionMessage: '0.0.1',
        trelloKey: process.env.TRELLO_KEY || null,
        trelloToken: process.env.TRELLO_TOKEN || null,
    },
});

/* 
    Ports out of Elm
*/

program.ports.print.subscribe((message) => {
    console.log(message);
});

program.ports.printAndExitFailure.subscribe((message) => {
    console.log(message);
    process.exit(1);
});

program.ports.printAndExitSuccess.subscribe((message) => {
    console.log(message);
    process.exit(0);
});

/*
    Port into Elm
*/

// program.ports.writeFile.subscribe(writeFile);

program.ports.readFile.subscribe((content) => readFile(program, content));

program.ports.runSolver.subscribe(runSolver);

/*
    Functions
*/

function writeFile([file, content]) {
    return fsPromise.writeFile(file, content).catch((err) => console.log(err));
}

function readFile(program, file) {
    return fsPromise
        .readFile(file)
        .then((content) => {
            program.ports.fileReceive.send(content.toString('utf-8'));
        })
        .catch((err) => console.log(err));
}

function runSolver([ranks, preference]) {
    minizinc(ranks, preference).then(program.ports.receiveSolverResult.send);
}
