import { BrowserModule } from '@angular/platform-browser';
import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';

import { FontAwesomeModule, FaIconLibrary } from '@fortawesome/angular-fontawesome';
import { faCoffee, fas } from '@fortawesome/free-solid-svg-icons';

import { HighlightModule } from 'ngx-highlightjs';

import { BackendInterceptor } from './interceptors/backend.interceptor';

import { AppRoutingModule } from './app-routing.module';

import { AppComponent } from './app.component';
import { OverviewComponent } from './components/overview/overview.component';
import { IndexComponent } from './components/index/index.component';
import { BrowserComponent } from './components/browser/browser.component';
import { FileListComponent } from './components/file-list/file-list.component';
import { AboutComponent } from './components/about/about.component';
import { FileComponent } from './components/file/file.component';
import { SearchResultComponent } from './components/search-result/search-result.component';

@NgModule({
  declarations: [
    AppComponent,
    OverviewComponent,
    IndexComponent,
    BrowserComponent,
    FileListComponent,
    AboutComponent,
    FileComponent,
    SearchResultComponent,
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    AppRoutingModule,
    FontAwesomeModule,
    HighlightModule
  ],
  providers: [
    {
      provide: HTTP_INTERCEPTORS,
      useClass: BackendInterceptor,
      multi: true
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { 
  constructor(library: FaIconLibrary) {
    library.addIconPacks(fas);
    library.addIcons(faCoffee);
  }
}
