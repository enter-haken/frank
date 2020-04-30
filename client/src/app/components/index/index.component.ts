import { Component, OnInit } from '@angular/core';

import { Observable } from 'rxjs';

import { Repo } from '../../models/repo';

import { GitService } from '../../services/git.service';

@Component({
  selector: 'app-index',
  templateUrl: './index.component.html',
  styleUrls: ['./index.component.scss']
})
export class IndexComponent implements OnInit {

  repos: Repo[];

  constructor(
    private gitService: GitService
  ) { }

  ngOnInit() {
    this.gitService.getRepos().subscribe(repoResponse => {
      this.repos = repoResponse.result;
    });
  }

}
