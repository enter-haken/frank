import { Component, OnInit, Input } from '@angular/core';

@Component({
  selector: 'app-overview',
  templateUrl: './overview.component.html',
  styleUrls: ['./overview.component.scss']
})
export class OverviewComponent {

  @Input() name: string;
  @Input() mainFiletype: string;
  @Input() license: string;
  @Input() fileCount: number;
  @Input() headBranch: string;
  @Input() url: string;
}
