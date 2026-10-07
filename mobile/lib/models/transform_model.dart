class SlotTransform {
  double zoom;
  double panX;
  double panY;
  int rotation; // 0, 90, 180, 270
  bool flipH;
  bool flipV;

  SlotTransform({
    this.zoom = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.rotation = 0,
    this.flipH = false,
    this.flipV = false,
  });

  SlotTransform copy() {
    return SlotTransform(
      zoom: zoom,
      panX: panX,
      panY: panY,
      rotation: rotation,
      flipH: flipH,
      flipV: flipV,
    );
  }

  void reset() {
    zoom = 1.0;
    panX = 0.0;
    panY = 0.0;
    rotation = 0;
    flipH = false;
    flipV = false;
  }
}
