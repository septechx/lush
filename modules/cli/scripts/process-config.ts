const configBytes = process.argv[2];
const configOut = await exec(configBytes);

process.stdout.write(JSON.stringify(configOut));

async function exec(js: string) {
  const blob = new Blob([js], { type: "text/javascript" });
  const url = URL.createObjectURL(blob);

  try {
    return await import(url);
  } finally {
    URL.revokeObjectURL(url);
  }
}

export {};
