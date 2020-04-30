import { Component, ElementRef, ViewChild, AfterViewInit, OnInit } from '@angular/core';

import { ActivatedRoute, Router, ParamMap, RoutesRecognized } from '@angular/router';

import { fromEvent } from 'rxjs';
import { debounceTime, map } from 'rxjs/operators';

import { GitService } from './services/git.service';
import { Search } from './models/search';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements AfterViewInit {
  title = 'Frank';
  searchResult: Search[] = [];
  repoName: string;
  referenceName: string;
  isLoading: boolean = false;

  @ViewChild('search', {static: false}) search: ElementRef;

  constructor(private gitService: GitService,
    private router: Router,
    private route: ActivatedRoute
  ) {
    this.router.events.subscribe(event => {
      if (event instanceof RoutesRecognized) {
        const referenceHasChanged = 
          this.referenceName != event.state.root.firstChild.params.reference_name;

        this.repoName = event.state.root.firstChild.params.repo_name;
        this.referenceName = event.state.root.firstChild.params.reference_name;

        if (referenceHasChanged) {
          this.searchResult = [];
          this.search.nativeElement.value = "";
        }
      }
    });
  }

  ngAfterViewInit() {
    fromEvent(this.search.nativeElement,'keyup')
      .pipe(
        map((i: any) => {
          this.isLoading = true; 
          return i.currentTarget.value;
        }),
        debounceTime(1000)
      )
      .subscribe(() => {
        if (!!this.search.nativeElement.value) {
          const isCurrentlyShowingRepoOverview = this.repoName == undefined && this.referenceName == undefined;

          if (isCurrentlyShowingRepoOverview) {
            this.gitService.searchOverview(
              this.search.nativeElement.value)
              .subscribe(rawSearchResult => {
                this.searchResult = rawSearchResult.result;
              });

          } else {
            this.gitService.search(
              this.repoName,
              this.referenceName,
              this.search.nativeElement.value)
              .subscribe(rawSearchResult => {
                this.searchResult = rawSearchResult.result;
              });

          }
        } else {
          this.searchResult = [];
        }
        this.isLoading = false;
      });
  }
}
