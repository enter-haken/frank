import { Link } from './link';

export enum GitObjectKind {
  blob, tree
}
export class GitObject {
  kind: GitObjectKind;
  path: string;
  url: string;
  breadcrumbs: Link[];
  client_url: string;
  hash: string;
  api_url: string;
  raw_content: string;
  formatted_content: string;
  commit_message: string;
  relative_committer_date: string;
}
