import { Component, Input } from '@angular/core';

import { GitObject } from '../../models/git-object';

@Component({
  selector: 'app-file-list',
  templateUrl: './file-list.component.html',
  styleUrls: ['./file-list.component.scss']
})
export class FileListComponent {

  @Input() files: GitObject[] = [];
}
