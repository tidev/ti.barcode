/*
 * Copyright (C) 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.zxing.client.android.camera;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Point;
import android.graphics.Rect;
import android.hardware.Camera;
import android.os.Handler;
import android.preference.PreferenceManager;
import android.util.Log;
import android.view.SurfaceHolder;
import com.google.zxing.client.android.PlanarYUVLuminanceSource;
import com.google.zxing.client.android.PreferencesActivity;

import java.io.IOException;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * This object wraps the Camera service object and expects to be the only one talking to it. The
 * implementation encapsulates the steps needed to take preview-sized images, which are used for
 * both preview and decoding.
 *
 * @author dswitkin@google.com (Daniel Switkin)
 */
public final class CameraManager {

  private static final String TAG = CameraManager.class.getSimpleName();

  private static final int MIN_FRAME_WIDTH = 240;
  private static final int MIN_FRAME_HEIGHT = 240;
  private static final int MAX_FRAME_WIDTH = 600;
  private static final int MAX_FRAME_HEIGHT = 400;

  private final Context context;
  private final CameraConfigurationManager configManager;
  private Camera camera;
  private Rect framingRect;
  private Rect framingRectInPreview;
  private boolean initialized;
  private boolean previewing;
  private boolean reverseImage;
  private int requestedFramingRectWidth;
  private int requestedFramingRectHeight;
  /**
   * Preview frames are delivered here, which we pass on to the registered handler. Make sure to
   * clear the handler so it will only receive one message.
   */
  private final PreviewCallback previewCallback;
  /** Autofocus callbacks arrive here, and are dispatched to the Handler which requested them. */
  private final AutoFocusCallback autoFocusCallback;

  public CameraManager(Context context) {
    this.context = context;
    this.configManager = new CameraConfigurationManager(context);
    previewCallback = new PreviewCallback(configManager);
    autoFocusCallback = new AutoFocusCallback();
  }
  
  public Camera getCamera() {
	  return camera;
  }

	/**
	 * Open the camera. First attempt to find and open the front-facing camera. If that attempt fails, then fall back to whatever camera is available.
	 * 
	 * Thanks to: http://digitaldumptruck.jotabout.com/?p=797
	 * 
	 * @return a Camera object
	 */
	private Camera openFrontFacingCamera() {
		Camera camera = null;

		// Look for front-facing camera, using the Gingerbread API.
		// Java reflection is used for backwards compatibility with pre-Gingerbread APIs.
		try {
			Class<?> cameraClass = Class.forName("android.hardware.Camera");
			Object cameraInfo = null;
			Field field = null;
			int cameraCount = 0;
			Method getNumberOfCamerasMethod = cameraClass.getMethod("getNumberOfCameras");
			if (getNumberOfCamerasMethod != null) {
				cameraCount = (Integer) getNumberOfCamerasMethod.invoke(null, (Object[]) null);
			}
			Class<?> cameraInfoClass = Class.forName("android.hardware.Camera$CameraInfo");
			if (cameraInfoClass != null) {
				cameraInfo = cameraInfoClass.newInstance();
			}
			if (cameraInfo != null) {
				field = cameraInfo.getClass().getField("facing");
			}
			Method getCameraInfoMethod = cameraClass.getMethod("getCameraInfo", Integer.TYPE, cameraInfoClass);
			if (getCameraInfoMethod != null && cameraInfoClass != null && field != null) {
				for (int camIdx = 0; camIdx < cameraCount; camIdx++) {
					getCameraInfoMethod.invoke(null, camIdx, cameraInfo);
					int facing = field.getInt(cameraInfo);
					if (facing == 1) { // Camera.CameraInfo.CAMERA_FACING_FRONT
						try {
							Method cameraOpenMethod = cameraClass.getMethod("open", Integer.TYPE);
							if (cameraOpenMethod != null) {
								camera = (Camera) cameraOpenMethod.invoke(null, camIdx);
							}
						} catch (RuntimeException e) {
							Log.e(TAG, "Camera failed to open: " + e.getLocalizedMessage());
						}
					}
				}
			}
		}
		// Ignore the bevy of checked exceptions the Java Reflection API throws - if it fails, who cares.
		catch (ClassNotFoundException e) {
			Log.e(TAG, "ClassNotFoundException" + e.getLocalizedMessage());
		} catch (NoSuchMethodException e) {
			Log.e(TAG, "NoSuchMethodException" + e.getLocalizedMessage());
		} catch (NoSuchFieldException e) {
			Log.e(TAG, "NoSuchFieldException" + e.getLocalizedMessage());
		} catch (IllegalAccessException e) {
			Log.e(TAG, "IllegalAccessException" + e.getLocalizedMessage());
		} catch (InvocationTargetException e) {
			Log.e(TAG, "InvocationTargetException" + e.getLocalizedMessage());
		} catch (InstantiationException e) {
			Log.e(TAG, "InstantiationException" + e.getLocalizedMessage());
		} catch (SecurityException e) {
			Log.e(TAG, "SecurityException" + e.getLocalizedMessage());
		}

		return camera;
	}
  /**
   * Opens the camera driver and initializes the hardware parameters.
   *
   * @param holder The surface object which the camera will draw preview frames into.
   * @throws IOException Indicates the camera driver failed to open.
   */
  public void openDriver(SurfaceHolder holder) throws IOException {
    boolean hadCamera = false;
    if (camera != null) {
      hadCamera = true;
      stopPreview();
      closeDriver();
    }
    // Should we try to use the front camera?
    if (configManager.getFrontCamera()) {
      camera = openFrontFacingCamera();
    }
    // If we aren't using the front camera, or if we didn't find the front facing camera...
    if (camera == null) {
      // Open the default back facing camera.
      camera = Camera.open();
    }
    // If we still can't find a camera to use (Camera.open() will return null if it can't find one)...
    if (camera == null) {
      // Then we need to give up. Our life as a module is over! Cry cry cry.
      throw new IOException();
    }
    camera.setPreviewDisplay(holder);

    if (!initialized) {
      initialized = true;
      configManager.initFromCameraParameters(camera);
      if (requestedFramingRectWidth > 0 && requestedFramingRectHeight > 0) {
        setManualFramingRect(requestedFramingRectWidth, requestedFramingRectHeight);
        requestedFramingRectWidth = 0;
        requestedFramingRectHeight = 0;
      }
    }
    configManager.setDesiredCameraParameters(camera);

    SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
    reverseImage = prefs.getBoolean(PreferencesActivity.KEY_REVERSE_IMAGE, false);
    if (hadCamera) {
      startPreview();
    }
  }

  /**
   * Closes the camera driver if still in use.
   */
  public void closeDriver() {
    if (camera != null) {
      camera.release();
      camera = null;
      // Make sure to clear these each time we close the camera, so that any scanning rect
      // requested by intent is forgotten.
      framingRect = null;
      framingRectInPreview = null;
    }
  }

  /**
   * Asks the camera hardware to begin drawing preview frames to the screen.
   */
  public void startPreview() {
    Camera theCamera = camera;
    if (theCamera != null && !previewing) {
      theCamera.startPreview();
      previewing = true;
    }
  }

  /**
   * Tells the camera to stop drawing preview frames.
   */
  public void stopPreview() {
    if (camera != null && previewing) {
      camera.stopPreview();
      previewCallback.setHandler(null, 0);
      autoFocusCallback.setHandler(null, 0);
      previewing = false;
    }
  }

  /**
   * A single preview frame will be returned to the handler supplied. The data will arrive as byte[]
   * in the message.obj field, with width and height encoded as message.arg1 and message.arg2,
   * respectively.
   *
   * @param handler The handler to send the message to.
   * @param message The what field of the message to be sent.
   */
  public void requestPreviewFrame(Handler handler, int message) {
    Camera theCamera = camera;
    if (theCamera != null && previewing) {
      previewCallback.setHandler(handler, message);
      theCamera.setOneShotPreviewCallback(previewCallback);
    }
  }

  /**
   * Asks the camera hardware to perform an autofocus.
   *
   * @param handler The Handler to notify when the autofocus completes.
   * @param message The message to deliver.
   */
  public void requestAutoFocus(Handler handler, int message) {
    if (camera != null && previewing) {
      autoFocusCallback.setHandler(handler, message);
      try {
        camera.autoFocus(autoFocusCallback);
      } catch (RuntimeException re) {
        // Have heard RuntimeException reported in Android 4.0.x+; continue?
        Log.w(TAG, "Unexpected exception while focusing", re);
      }
    }
  }

  /**
   * Calculates the framing rect which the UI should draw to show the user where to place the
   * barcode. This target helps with alignment as well as forces the user to hold the device
   * far enough away to ensure the image will be in focus.
   *
   * @return The rectangle to draw on screen in window coordinates.
   */
  public Rect getFramingRect() {
    if (framingRect == null) {
      if (camera == null) {
        return null;
      }
      Point screenResolution = configManager.getScreenResolution();
      int width = screenResolution.x * 3 / 4;
      if (width < MIN_FRAME_WIDTH) {
        width = MIN_FRAME_WIDTH;
      } else if (width > MAX_FRAME_WIDTH) {
        width = MAX_FRAME_WIDTH;
      }
      int height = screenResolution.y * 3 / 4;
      if (height < MIN_FRAME_HEIGHT) {
        height = MIN_FRAME_HEIGHT;
      } else if (height > MAX_FRAME_HEIGHT) {
        height = MAX_FRAME_HEIGHT;
      }
      int leftOffset = (screenResolution.x - width) / 2;
      int topOffset = (screenResolution.y - height) / 2;
      framingRect = new Rect(leftOffset, topOffset, leftOffset + width, topOffset + height);
      Log.d(TAG, "Calculated framing rect: " + framingRect);
    }
    return framingRect;
  }

  /**
   * Like {@link #getFramingRect} but coordinates are in terms of the preview frame,
   * not UI / screen.
   */
  public Rect getFramingRectInPreview() {
    if (framingRectInPreview == null) {
      Rect framingRect = getFramingRect();
      if (framingRect == null) {
        return null;
      }
      Rect rect = new Rect(framingRect);
      Point cameraResolution = configManager.getCameraResolution();
      Point screenResolution = configManager.getScreenResolution();
      rect.left = rect.left * cameraResolution.x / screenResolution.x;
      rect.right = rect.right * cameraResolution.x / screenResolution.x;
      rect.top = rect.top * cameraResolution.y / screenResolution.y;
      rect.bottom = rect.bottom * cameraResolution.y / screenResolution.y;
      framingRectInPreview = rect;
    }
    return framingRectInPreview;
  }

  /**
   * Allows third party apps to specify the scanning rectangle dimensions, rather than determine
   * them automatically based on screen resolution.
   *
   * @param width The width in pixels to scan.
   * @param height The height in pixels to scan.
   */
  public void setManualFramingRect(int width, int height) {
    if (initialized) {
      Point screenResolution = configManager.getScreenResolution();
      if (width > screenResolution.x) {
        width = screenResolution.x;
      }
      if (height > screenResolution.y) {
        height = screenResolution.y;
      }
      int leftOffset = (screenResolution.x - width) / 2;
      int topOffset = (screenResolution.y - height) / 2;
      framingRect = new Rect(leftOffset, topOffset, leftOffset + width, topOffset + height);
      Log.d(TAG, "Calculated manual framing rect: " + framingRect);
      framingRectInPreview = null;
    } else {
      requestedFramingRectWidth = width;
      requestedFramingRectHeight = height;
    }
  }

  /**
   * A factory method to build the appropriate LuminanceSource object based on the format
   * of the preview buffers, as described by Camera.Parameters.
   *
   * @param data A preview frame.
   * @param width The width of the image.
   * @param height The height of the image.
   * @return A PlanarYUVLuminanceSource instance.
   */
  public PlanarYUVLuminanceSource buildLuminanceSource(byte[] data, int width, int height) {
    Rect rect = getFramingRectInPreview();
    if (rect == null) {
      return null;
    }
    // Go ahead and assume it's YUV rather than die.
    return new PlanarYUVLuminanceSource(data, width, height, rect.left, rect.top,
                                        rect.width(), rect.height(), reverseImage);
  }

}
