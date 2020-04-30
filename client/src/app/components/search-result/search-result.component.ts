import { Component, Input } from '@angular/core';

import { Search } from '../../models/search';

@Component({
  selector: 'app-search-result',
  templateUrl: './search-result.component.html',
  styleUrls: ['./search-result.component.scss']
})
export class SearchResultComponent {

  @Input() result: Search[];

}
