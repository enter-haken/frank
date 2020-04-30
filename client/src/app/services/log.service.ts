import { isDevMode, Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class LogService {
  constructor() {}

  public log(...args: any[]): void {
    if (isDevMode()) {
      for (const arg of args) {
        console.log(arg);
      }
    } else {
      window.console.log = () => {};
    }
  }
}

