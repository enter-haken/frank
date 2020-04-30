import { GitObject } from './git-object';

export class GitTree {
  gitObject: GitObject;
  content: string;
  directory: GitObject[];
}
