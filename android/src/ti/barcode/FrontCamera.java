package ti.barcode;

import android.hardware.Camera;
import android.util.Log;
import com.google.zxing.client.android.camera.open.CameraFacing;

public class FrontCamera {
	

	public static int getFrontCamera() {
		int index = 0;
		int numCameras = Camera.getNumberOfCameras();
		if (numCameras == 0) {
			Log.w("BarcodeModule", "No cameras!");
			return -1;
		}

		while (index < numCameras) {
			Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
			Camera.getCameraInfo(index, cameraInfo);
			CameraFacing reportedFacing = CameraFacing.values()[cameraInfo.facing];
			if (reportedFacing == CameraFacing.FRONT) {
				return index;
			}
			index++;
		}
		
		return -1;
	}
}
