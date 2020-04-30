import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { IndexComponent } from './components/index/index.component';
import { AboutComponent } from './components/about/about.component';
import { BrowserComponent } from './components/browser/browser.component';


const routes: Routes = [
  {path: '', redirectTo: 'repos', pathMatch: 'full'},
  {path: 'repos', component: IndexComponent},
  {path: 'about', component: AboutComponent},
  {path: 'repos/:repo_name/:reference_name', children: [
    {path: '**',  component: BrowserComponent}
  ]
  }
];

@NgModule({
  imports: [RouterModule.forRoot(routes, {
    useHash: true
  })],
  exports: [RouterModule]
})

export class AppRoutingModule { }
