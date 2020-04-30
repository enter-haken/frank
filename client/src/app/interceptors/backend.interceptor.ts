import { Injectable, isDevMode } from '@angular/core';
import {
  HTTP_INTERCEPTORS,
  HttpEvent,
  HttpHandler,
  HttpInterceptor,
  HttpRequest
} from '@angular/common/http';

import { Observable, of, throwError } from 'rxjs';
import {
  delay,
  mergeMap,
  materialize,
  dematerialize,
  tap,
} from 'rxjs/operators';

import { LogService } from '../services/log.service';

import { environment } from '../../environments/environment';

@Injectable()
export class BackendInterceptor implements HttpInterceptor {
  constructor(
    private logService: LogService
  ) {}

  intercept(
    request: HttpRequest<any>,
    next: HttpHandler
  ): Observable<HttpEvent<any>> {
    //this.logService.log(request);

    return next.handle(request);
  }

}

