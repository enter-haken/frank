import { Component, OnInit, ViewChildren, AfterViewInit, ElementRef, QueryList } from '@angular/core';

import { ActivatedRoute, ParamMap, Router, RoutesRecognized } from '@angular/router';

import { fromEvent } from 'rxjs';

import { GitObject } from '../../models/git-object';
import { Link } from '../../models/link';

import { GitService } from '../../services/git.service';

@Component({
  selector: 'app-browser',
  templateUrl: './browser.component.html',
  styleUrls: ['./browser.component.scss']
})
export class BrowserComponent implements OnInit, AfterViewInit {

  current: GitObject;
  repoName: string;
  referenceName: string;
  files: GitObject[] = [];
  branches: Link[] = [];

  @ViewChildren('branch') branch: QueryList<ElementRef>;

  constructor(private route: ActivatedRoute,
    private router: Router,
    private gitService: GitService) {

    this.repoName = this.route.snapshot.params.repo_name;
    this.referenceName = this.route.snapshot.params.reference_name;

    this.router.events.subscribe(event => {
      if (event instanceof RoutesRecognized) {
        this.repoName = event.state.root.firstChild.params.repo_name;
        this.referenceName = event.state.root.firstChild.params.reference_name;
      }
    });

  }

  ngOnInit() {
    this.gitService.getBranches(this.repoName)
      .subscribe(repoResponse => {
        this.branches = repoResponse.result;
      });

    this.route.params.subscribe(params => {
      this.gitService.getBranch(this.repoName, this.referenceName)
        .subscribe(repoResponse => {
          this.current = repoResponse.result.gitObject;
          this.files = repoResponse.result.directory;

        });
    });

    this.route.url.subscribe(url =>{
      if (url.length == 0) {
        this.gitService.getBranch(this.repoName, this.referenceName)
          .subscribe(repoResponse => {
            this.current = repoResponse.result.gitObject;
            this.files = repoResponse.result.directory;
          });
      } else {
        this.gitService.getObject(
          this.repoName,
          this.referenceName,
          url.join("/")).subscribe(repoResponse => {
            this.current = repoResponse.result.gitObject;
            this.files = repoResponse.result.directory;
          });
      }
    });
  }

  ngAfterViewInit() {
    this.branch.changes
      .subscribe(raw => {
        fromEvent(raw.first.nativeElement,'change')
          .subscribe((selection: any) => this.router.navigate(['/','repos', this.repoName, selection.target.value]));
      });
  }
}
