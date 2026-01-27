/**
 * Node represents a single piece of content in a cluster
 * Can be a highlight, note, or photo OCR text
 */
export interface Node {
  id: string;
  type: "highlight" | "note" | "photo_ocr";
  content: string;
  pageNumber?: number;
  sourceId?: string;
}

/**
 * Connection represents a relationship between two nodes
 */
export interface Connection {
  fromNodeId: string;
  toNodeId: string;
  reason: string;
}

/**
 * Cluster groups related nodes together with a theme
 */
export interface Cluster {
  id: string;
  name: string;
  summary: string;
  nodes: Node[];
}

/**
 * NoteStructure is the complete mindmap structure for a book
 * Contains clusters of related notes and connections between them
 */
export interface NoteStructure {
  bookId: string;
  generatedAt: string; // ISO 8601 datetime
  clusters: Cluster[];
  connections: Connection[];
}
