package com.google.zxing.client.android;

import android.content.Context;
import android.util.AttributeSet;
import android.view.SurfaceView;

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

    float previewRatio = previewWidth / (float) previewHeight;
    float parentRatio = parentWidth / (float) parentHeight;

    int measuredWidth;
    int measuredHeight;
    if (parentRatio < previewRatio) {
      measuredWidth = Math.round(parentHeight * previewRatio);
      measuredHeight = parentHeight;
    } else {
      measuredWidth = parentWidth;
      measuredHeight = Math.round(parentWidth / previewRatio);
    }

    setMeasuredDimension(measuredWidth, measuredHeight);
  }
}
