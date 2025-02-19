export function stringify(obj: Object) {
  let str = "(";

  for (const key of Object.keys(obj)) {
    const val = obj[key];

    switch (typeof val) {
      case "number":
        str += genKeyVal(key, val.toString());
        break;
      case "string":
        str += genKeyStr(key, val);
        break;
      case "object":
        if (Array.isArray(val)) {
          str += genKeyVal(key, stringifyArr(val));
        } else {
          str += genKeyVal(key, stringify(val));
        }
        break;
      case "boolean":
        str += genKeyVal(key, `${val}`);
        break;
    }
  }

  str += ")";

  return str;
}

function stringifyArr(arr: any[]) {
  let str = "[";

  for (const item of arr) {
    str += `${item},`;
  }

  str += "]";

  return str;
}

function genKeyStr(key: string, val: string) {
  return `${key}="${val}",`;
}

function genKeyVal(key: string, val: string) {
  return `${key}=${val},`;
}
