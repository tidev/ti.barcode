package com.google.zxing.client.android;

import android.content.Context;
import android.graphics.Point;
import android.graphics.Rect;
import android.util.AttributeSet;
import android.view.SurfaceView;

import com.google.zxing.client.android.camera.CameraManager;

public class PreviewSurfaceView extends SurfaceView {

  private int previewHeight;
  private int previewWidth;

  public PreviewSurfaceView(Context context, AttributeSet attrs) {
    super(context, attrs);
  }

  public void setPreviewSize(int width, int height) {
    previewWidth = width;
    previewHeight = height;
    requestLayout();
  }

  @Override
  protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    int parentWidth = MeasureSpec.getSize(widthMeasureSpec);
    int parentHeight = MeasureSpec.getSize(heightMeasureSpec);

    if (previewWidth <= 0 || previewHeight <= 0 || parentWidth <= 0 || parentHeight <= 0) {
      super.onMeasure(widthMeasureSpec, heightMeasureSpec);
      return;
    }

    // Reuse the exact center-crop math CameraManager uses to model the preview on screen,
    // so the rendered preview and the decode mapping can never drift apart.
    Rect previewRect = CameraManager.getPreviewRectOnScreen(new Point(parentWidth, parentHeight),
                                                            new Point(previewWidth, previewHeight));
    setMeasuredDimension(previewRect.width(), previewRect.height());
  }
}
