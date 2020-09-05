const config = require('../../config');

import { IJob, IJobResult } from '../types';

import { rm, mkdir, exec, cat } from 'shelljs';
import * as path from 'path';
import * as fs from 'fs';

rm('-rf', config.WORKER.BOX_DIR);
mkdir('-p', config.WORKER.BOX_DIR);

const worker = async (message: IJob) => {
  const jobExecutionPath = path.join(config.WORKER.BOX_DIR, `${message.id}`);
  mkdir('-p', jobExecutionPath);

  const LANG_CONFIG = config.WORKER.LANG[message.lang];
  const CONTAINER_BASE_PATH = config.WORKER.CONTAINER_BASE_PATH;

  fs.writeFileSync(
    path.join(jobExecutionPath, LANG_CONFIG.SOURCE_FILE),
    (new Buffer(message.source, 'base64')).toString('ascii')
  );

  fs.writeFileSync(
    path.join(jobExecutionPath, 'run.stdin'),
    (new Buffer(message.stdin, 'base64')).toString('ascii')
  );

  const shellOutput = exec(`docker run \\
    --cpus="${LANG_CONFIG.CPU_SHARES}" \\
    --memory="${LANG_CONFIG.MEM_LIMIT}" \\
    --ulimit nofile=64:64 \\
    --rm \\
    --read-only \\
    -v ${jobExecutionPath}:${config.WORKER.BOX_DIR} \\
    -w ${config.WORKER.BOX_DIR} \\
    -e DEFAULT_TIMEOUT=${message.timeoutSeconds || 5} \\
    --network no-internet \\
    ${CONTAINER_BASE_PATH}/ide-worker-${message.lang} \\
    bash -c "/bin/compile.sh && /bin/run.sh"
  `);

  const compile_stdout_file = path.join(jobExecutionPath, 'compile.stdout');
  const compile_stdout = fs.existsSync(compile_stdout_file) ? cat(compile_stdout_file).stdout : '';

  const compile_stderr_file = path.join(jobExecutionPath, 'compile.stderr');
  const compile_stderr = fs.existsSync(compile_stderr_file) ? cat(compile_stderr_file).stdout : '';

  const stdout_file = path.join(jobExecutionPath, 'run.stdout');
  const stdout = fs.existsSync(stdout_file) ? cat(stdout_file).stdout : '';

  const stderr_file = path.join(jobExecutionPath, 'run.stderr');
  const stderr = fs.existsSync(stderr_file) ? cat(stderr_file).stdout : '';

  const tle_err_file = path.join(jobExecutionPath, 'tle.stderr');
  const tle_err = fs.existsSync(tle_err_file) ? cat(tle_err_file).stdout : '';

  let is_worker_error = false;
  let isRuntimeErr = false;

  const time_log_file = path.join(jobExecutionPath, 'time.log');

  let exec_time = '0.00';
  let exit_status = '0';

  if (fs.existsSync(time_log_file)) {
    exec_time = exec(`< ${time_log_file} head -n 1`).stdout;
    exit_status = exec(`< ${time_log_file} sed "3q;d"`).stdout;
  } else {
    is_worker_error = true
  }

  if (exit_status !== '0\n') {
    isRuntimeErr = true;
  }

  let isTLE = false;
  if (tle_err.slice(0, 3) === 'TLE') {
    isTLE = true;
    exec_time = '5.00'
  }

  const output: IJobResult = {
    job: message,
    compile_stdout,
    compile_stderr,
    stdout,
    stderr,
    exec_time,
    isTLE,
    isRuntimeErr,
    is_worker_error
  };

  rm('-rf', jobExecutionPath);

  return { shellOutput, output };
};

export = worker;
