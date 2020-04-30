import { Injectable } from '@angular/core';

import { HttpClient } from '@angular/common/http';

import { Observable } from 'rxjs';

import { Repo } from '../models/repo';
import { Link } from '../models/link';
import { GitObject } from '../models/git-object';
import { GitTree } from '../models/git-tree';
import { Search } from '../models/search';
import { Response } from '../models/response';


@Injectable({
  providedIn: 'root'
})
export class GitService {

  constructor(private http: HttpClient) { }

  getRepos(): Observable<Response<Repo[]>> {
    return this.http.get<Response<Repo[]>>('/api/repos');
  }

  getHead(repoName): Observable<Response<GitTree>> {
    return this.http.get<Response<GitTree>>(`/api/repos/${repoName}`);
  }

  getBranches(repoName): Observable<Response<Link[]>> {
    return this.http.get<Response<Link[]>>(`/api/repos/${repoName}/branches`);
  }

  getBranch(repoName, branchName): Observable<Response<GitTree>> {
    return this.http.get<Response<GitTree>>(`/api/repos/${repoName}/branches/${branchName}`);
  }

  getObject(repoName, branchName, objectPath): Observable<Response<GitTree>> {
    return this.http.get<Response<GitTree>>(`/api/repos/${repoName}/branches/${branchName}/${objectPath}`);
  }

  searchOverview(searchTerm): Observable<Response<Search[]>> {
    return this.http.post<Response<Search[]>>(`/api/search`, {
      searchTerm: searchTerm
    });
  }

  search(repoName, branchName, searchTerm): Observable<Response<Search[]>> {
    return this.http.post<Response<Search[]>>(`/api/repos/${repoName}/branches/${branchName}/search`, {
      searchTerm: searchTerm
    });
  }
}
