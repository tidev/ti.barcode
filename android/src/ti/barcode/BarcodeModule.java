/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2013 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

package ti.barcode;

import java.util.Hashtable;
import java.util.Vector;
import java.util.HashMap;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.TiBlob;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.util.TiActivityResultHandler;
import org.appcelerator.titanium.util.TiActivitySupport;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.view.TiDrawableReference;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.Result;
import com.google.zxing.ResultPoint;
import com.google.zxing.client.android.CaptureActivity;
import com.google.zxing.client.android.Intents;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.client.android.PreferencesActivity;
import com.google.zxing.client.android.camera.CameraManager;
import com.google.zxing.client.result.ParsedResult;
import com.google.zxing.client.result.ResultParser;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.client.android.camera.CameraConfigurationManager;
import com.google.zxing.client.android.camera.open.OpenCamera;
import com.google.zxing.client.android.camera.open.OpenCameraInterface;
import com.google.zxing.client.android.camera.open.CameraFacing;
import ti.barcode.FrontCamera;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager.NameNotFoundException;
import android.graphics.Bitmap;
import android.preference.PreferenceManager;

@Kroll.module(name = "Barcode", id = "ti.barcode", propertyAccessors = { "displayedMessage", "allowRotation" })
public class BarcodeModule extends KrollModule implements TiActivityResultHandler {

	// Standard Debugging variables
	private static final String LCAT = "BarcodeModule";
	private boolean keepOpen = false;

	public int frameWidth = 0;
	public int frameHeight = 0;

	@Kroll.constant
	public static final int UNKNOWN = 0;
	@Kroll.constant
	public static final int URL = 1;
	@Kroll.constant
	public static final int SMS = 2;
	@Kroll.constant
	public static final int TELEPHONE = 3;
	@Kroll.constant
	public static final int TEXT = 4;
	@Kroll.constant
	public static final int CALENDAR = 5;
	@Kroll.constant
	public static final int GEOLOCATION = 6;
	@Kroll.constant
	public static final int EMAIL = 7;
	@Kroll.constant
	public static final int CONTACT = 8;
	@Kroll.constant
	public static final int BOOKMARK = 9;
	@Kroll.constant
	public static final int WIFI = 10;

	private static final String[] FORMAT_STRINGS = new String[] { "NONE", "QR_CODE", "DATA_MATRIX", "UPC_E", "UPC_A", "EAN_8", "EAN_13", "CODE_128",
			"CODE_39", "ITF" };

	@Kroll.constant
	public static final int FORMAT_NONE = 0;
	@Kroll.constant
	public static final int FORMAT_QR_CODE = 1;
	@Kroll.constant
	public static final int FORMAT_DATA_MATRIX = 2;
	@Kroll.constant
	public static final int FORMAT_UPC_E = 3;
	@Kroll.constant
	public static final int FORMAT_UPC_A = 4;
	@Kroll.constant
	public static final int FORMAT_EAN_8 = 5;
	@Kroll.constant
	public static final int FORMAT_EAN_13 = 6;
	@Kroll.constant
	public static final int FORMAT_CODE_128 = 7;
	@Kroll.constant
	public static final int FORMAT_CODE_39 = 8;
	@Kroll.constant
	public static final int FORMAT_ITF = 9;


	public BarcodeModule() {
		super();
	}

	private static BarcodeModule _instance;

	public static BarcodeModule getInstance() {
		return _instance;
	}

	// Methods

	@Kroll.method
	public void cancel() {
		_instance = null;
		CaptureActivity.getInstance().cancel();
	}

	@Kroll.method
	@Kroll.getProperty
	public boolean getUseFrontCamera() {
		return new CameraConfigurationManager(getActivity()).getFrontCamera();
	}

	@Kroll.method
	@Kroll.setProperty
	public void setUseFrontCamera(boolean value) {
		new CameraConfigurationManager(getActivity()).setFrontCamera(value);
		if (CaptureActivity.getInstance() != null) {
			CaptureActivity.getInstance().getCameraManager().setManualCameraId(FrontCamera.getFrontCamera());
			CaptureActivity.getInstance().reset();
		}
	}

	@Kroll.method
	@Kroll.getProperty
	public boolean getUseLED() {
		return CaptureActivity.getInstance().getCameraManager().getTorch();
	}

	@Kroll.method
	@Kroll.setProperty
	public void setUseLED(boolean value) {
		new CameraConfigurationManager(getActivity()).setTorch(null, value);
		if (CaptureActivity.getInstance() != null) {
			CaptureActivity.getInstance().getCameraManager().setTorch(value);
		}
	}

	static final Vector<BarcodeFormat> PRODUCT_FORMATS;
	static final Vector<BarcodeFormat> ONE_D_FORMATS;
	static final Vector<BarcodeFormat> QR_CODE_FORMATS;
	static final Vector<BarcodeFormat> DATA_MATRIX_FORMATS;
	static {
		PRODUCT_FORMATS = new Vector<BarcodeFormat>(5);
		PRODUCT_FORMATS.add(BarcodeFormat.UPC_A);
		PRODUCT_FORMATS.add(BarcodeFormat.UPC_E);
		PRODUCT_FORMATS.add(BarcodeFormat.EAN_13);
		PRODUCT_FORMATS.add(BarcodeFormat.EAN_8);
		PRODUCT_FORMATS.add(BarcodeFormat.RSS_14);
		ONE_D_FORMATS = new Vector<BarcodeFormat>(PRODUCT_FORMATS.size() + 4);
		ONE_D_FORMATS.addAll(PRODUCT_FORMATS);
		ONE_D_FORMATS.add(BarcodeFormat.CODE_39);
		ONE_D_FORMATS.add(BarcodeFormat.CODE_93);
		ONE_D_FORMATS.add(BarcodeFormat.CODE_128);
		ONE_D_FORMATS.add(BarcodeFormat.ITF);
		QR_CODE_FORMATS = new Vector<BarcodeFormat>(1);
		QR_CODE_FORMATS.add(BarcodeFormat.QR_CODE);
		DATA_MATRIX_FORMATS = new Vector<BarcodeFormat>(1);
		DATA_MATRIX_FORMATS.add(BarcodeFormat.DATA_MATRIX);
	}

	// Inspired in large part by:
	// http://ketai.googlecode.com/svn/trunk/ketai/src/edu/uic/ketai/inputService/KetaiCamera.java
	private void populateYUVLuminanceFromRGB(int[] rgb, byte[] yuv420sp, int width, int height) {
		for (int i = 0; i < width * height; i++) {
			float red = (rgb[i] >> 16) & 0xff;
			float green = (rgb[i] >> 8) & 0xff;
			float blue = (rgb[i]) & 0xff;
			int luminance = (int) ((0.257f * red) + (0.504f * green) + (0.098f * blue) + 16);
			yuv420sp[i] = (byte) (0xff & luminance);
		}
	}

	@SuppressWarnings("rawtypes")
	private Hashtable<DecodeHintType, Object> populateHints(HashMap args) {
		Vector<BarcodeFormat> decodeFormats = new Vector<BarcodeFormat>();
		Hashtable<DecodeHintType, Object> hints = new Hashtable<DecodeHintType, Object>();
		if (args.containsKey("acceptedFormats")) {
			Object[] acceptedFormats = (Object[]) args.get("acceptedFormats");
			if (acceptedFormats.length > 0) {
				for (Object acceptedFormat : acceptedFormats) {
					decodeFormats.add(BarcodeFormat.valueOf(FORMAT_STRINGS[TiConvert.toInt(acceptedFormat)]));
				}
			}
		} else {
			Activity activity = TiApplication.getAppCurrentActivity();
			SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(activity);
			decodeFormats = new Vector<BarcodeFormat>();
			// if (prefs.getBoolean(PreferencesActivity.KEY_DECODE_1D, true)) {
			// 	decodeFormats.addAll(ONE_D_FORMATS);
			// }
			if (prefs.getBoolean(PreferencesActivity.KEY_DECODE_QR, true)) {
				decodeFormats.addAll(QR_CODE_FORMATS);
			}
			if (prefs.getBoolean(PreferencesActivity.KEY_DECODE_DATA_MATRIX, true)) {
				decodeFormats.addAll(DATA_MATRIX_FORMATS);
			}
		}
		hints.put(DecodeHintType.POSSIBLE_FORMATS, decodeFormats);
		return hints;
	}

	@Kroll.method
	@SuppressWarnings({ "rawtypes" })
	public void parse(@Kroll.argument(optional = false) HashMap args) {
		_instance = this;

		try {

			TiBlob blob = (TiBlob) args.get("image");
			TiDrawableReference ref = TiDrawableReference.fromBlob(TiApplication.getAppCurrentActivity(), blob);
			Bitmap image = ref.getBitmap();

			int w = image.getWidth(), h = image.getHeight();
			int[] rgb = new int[w * h];
			byte[] yuv = new byte[w * h];

			image.getPixels(rgb, 0, w, 0, 0, w, h);
			populateYUVLuminanceFromRGB(rgb, yuv, w, h);

			PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(yuv, w, h, 0, 0, w, h, false);
			BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
			MultiFormatReader reader = new MultiFormatReader();
			reader.setHints(populateHints(args));

			Result rawResult = reader.decode(bitmap);
			String format = rawResult.getBarcodeFormat().toString();
			String result = rawResult.toString();
			processResult(format, result, Activity.RESULT_OK);

		} catch (NotFoundException e) {
			HashMap<String, Object> errdict = new HashMap<String, Object>();
			errdict.put("message", "Scan Failed");
			errdict.put("exception", e.toString());
			fireEvent("error", errdict);
		}
	}

	@Kroll.method
	@SuppressWarnings({ "rawtypes", "unchecked" })
	public void capture(@Kroll.argument(optional = true) HashMap args) {
		_instance = this;

		Intent intent = new Intent(Intents.Scan.ACTION);
		
		if (args != null) {
			KrollDict argsDict = new KrollDict(args);
			
			// [MOD-233] Turn off default animation if requested. It is on by default.
			boolean animate = argsDict.optBoolean("animate", true);
			if (!animate) {
				// Note that this is only available in API level 5 and above, so if you receive compile warnings, bump up the version of Android you
				// are pointing at.
				intent.setFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
			}

			if (args.containsKey("overlay")) {
				Intents.Scan.overlayProxy = (TiViewProxy) args.get("overlay");
			} else {
				Intents.Scan.overlayProxy = null;
			}

			if (args.containsKey("acceptedFormats")) {
				Object[] acceptedFormats = (Object[]) args.get("acceptedFormats");
				if (acceptedFormats.length > 0) {
					String formats = "";
					for (Object acceptedFormat : acceptedFormats) {
						formats += FORMAT_STRINGS[TiConvert.toInt(acceptedFormat)] + ",";
					}
					Log.d(LCAT, formats.substring(0, formats.length() - 1));
					intent.putExtra(Intents.Scan.FORMATS, formats.substring(0, formats.length() - 1));
				}
			}

			intent.putExtra(Intents.Scan.SHOW_RECTANGLE, argsDict.optBoolean("showRectangle", true));
			intent.putExtra(Intents.Scan.KEEP_OPEN, argsDict.optBoolean("keepOpen", false));

			intent.putExtra(Intents.Scan.SHOW_INFO_TEXT, argsDict.optBoolean("showInfoText", false));
		} else {
			
			Intents.Scan.overlayProxy = null;
			intent.putExtra(Intents.Scan.SHOW_RECTANGLE, true);
			intent.putExtra(Intents.Scan.KEEP_OPEN, false);
			intent.putExtra(Intents.Scan.SHOW_INFO_TEXT, false);
		}

		intent.putExtra(Intents.Scan.ALLOW_MENU, properties.optBoolean("allowMenu", true));
		intent.putExtra(Intents.Scan.ALLOW_INSTRUCTIONS, properties.optBoolean("allowInstructions", true));
		intent.putExtra(Intents.Scan.PROMPT_MESSAGE, properties.optString("displayedMessage", null));


		// [MOD-217] -- Must set the package in order for it to automatically select the application as the source of the scanning activity.
		intent.setPackage(TiApplication.getInstance().getPackageName());
		// CaptureActivity.PACKAGE_NAME = TiApplication.getInstance().getPackageName();

		Activity activity = TiApplication.getAppCurrentActivity();
		TiActivitySupport activitySupport = (TiActivitySupport) activity;
		final int resultCode = activitySupport.getUniqueResultCode();
		activitySupport.launchActivityForResult(intent, resultCode, this);
	}


	@Override
	public void onError(Activity activity, int requestCode, Exception e) {
		HashMap<String, Object> errdict = new HashMap<String, Object>();
		errdict.put("message", "Scan Failed");
		errdict.put("code", requestCode);
		fireEvent("error", errdict);
	}

	public void processFailed(int resultCode) {
		Log.w(LCAT, "Result for scan was not OK: " + Activity.RESULT_CANCELED);
		// for (String key : data.getExtras().keySet()) { Log.d(LCAT, "intent extra: " + key + ", value: " + data.getExtras().get(key)); }
		HashMap<String, Object> errdict = new HashMap<String, Object>();
		errdict.put("message", "Scan Failed");
		errdict.put("code", resultCode);
		fireEvent("error", errdict);
	}

	public void processCanceled(int resultCode) {
		Log.w(LCAT, "Result for scan was CANCELED");
		HashMap<String, Object> cancelDict = new HashMap<String, Object>();
		cancelDict.put("message", "Scan Canceled");
		cancelDict.put("code", resultCode);
		fireEvent("cancel", cancelDict);
	}

	public void processResult(String format, String contents, int resultCode) {
		int contentType = getContentType(format, contents);
		HashMap<String, Object> dict = new HashMap<String, Object>();
		dict.put("format", format);
		dict.put("result", contents);
		dict.put("code", resultCode);
		dict.put("contentType", contentType);
		dict.put("data", parseData(contentType, contents));
		fireEvent("success", dict);
	}

	@Override
	public void onResult(Activity activity, int requestCode, int resultCode, Intent data) {
		if (resultCode != Activity.RESULT_OK && resultCode != Activity.RESULT_CANCELED) {
			processFailed(resultCode);
			return;
		} else if (resultCode == Activity.RESULT_CANCELED) {
			processCanceled(resultCode);
			return;
		}

		try {
			processResult(data.getStringExtra(Intents.Scan.RESULT_FORMAT), data.getStringExtra(Intents.Scan.RESULT), resultCode);
		} catch (Exception e) {
			Log.e(LCAT, "Hit exception while processing barcode! " + e.toString());
			e.printStackTrace();
			processFailed(resultCode);
		}
		
		if (!keepOpen) {
			_instance = null;
		}
	}

	private int getContentType(String format, String contents) {
		if (format.equals("QR_CODE")) {
			ParsedResult res = ResultParser.parseResult(new Result(contents, new byte[0], new ResultPoint[0], BarcodeFormat.QR_CODE));
			switch (res.getType()) {
				case ADDRESSBOOK:
					return CONTACT;
				case EMAIL_ADDRESS:
					return EMAIL;
				case URI:
					return URL;
				case TEXT:
					return TEXT;
				case GEO:
					return GEOLOCATION;
				case TEL:
					return TELEPHONE;
				case SMS:
					return SMS;
				case CALENDAR:
					return CALENDAR;
				case WIFI:
					return WIFI;

				case PRODUCT:
				case ISBN:
				default:
					break;
			}
		}
		return TEXT;
	}

	private HashMap<String, Object> parseData(int contentType, String contents) {
		HashMap<String, Object> retVal = new HashMap<String, Object>();
		switch (contentType) {
			case URL:
				retVal.put("url", contents);
				break;
			case SMS:
				parseSMS(retVal, contents);
				break;
			case TELEPHONE:
				retVal.put("phonenumber", contents.substring(4));
				break;
			case TEXT:
				retVal.put("text", contents);
				break;
			case CALENDAR:
				parseCalendar(retVal, contents);
				break;
			case GEOLOCATION:
				parseGeo(retVal, contents);
				break;
			case EMAIL:
				parseEmail(retVal, contents);
				break;
			case CONTACT:
				parseContact(retVal, contents);
				break;
			case BOOKMARK:
				retVal.put("text", contents);
				break;
			case WIFI:
				parseWifi(retVal, contents);
				break;
			case UNKNOWN:
			default:
				retVal.put("text", contents);
				break;
		}
		return retVal;
	}

	private void parseGeo(HashMap<String, Object> retVal, String contents) {
		String latitude;
		String longitude;
		String[] split = contents.split(":")[1].split(",");
		if (split.length == 2) {
			latitude = split[0];
			longitude = split[1];
			String[] qSplit = longitude.split("\\?");
			if (qSplit.length == 2) {
				longitude = qSplit[0];
				retVal.put("query", qSplit[1].substring(2));
			}
			retVal.put("latitude", latitude);
			retVal.put("longitude", longitude);
		} else {
			retVal.put("text", contents);
		}
	}

	private void parseSMS(HashMap<String, Object> retVal, String contents) {
		String parsed = contents.substring(6);
		if (parsed.contains(":")) {
			String[] split = parsed.split(":");
			retVal.put("phonenumber", split[0]);
			retVal.put("message", split[1]);
		} else {
			retVal.put("phonenumber", parsed);
		}
	}

	private void parseEmail(HashMap<String, Object> retVal, String contents) {
		String parsed = contents.substring(7);
		if (contents.contains("?")) {
			String[] query = contents.split("?");
			retVal.put("email", query[0]);
			String[] addt = query[1].split("&");
			for (String pairs : addt) {
				String[] pair = pairs.split("=");
				retVal.put(pair[0].toLowerCase(), pair[1]);
			}
		} else {
			retVal.put("email", parsed);
		}
	}

	private void parseContact(HashMap<String, Object> retVal, String contents) {
		String[] split = contents.substring(7).split(";");
		for (String line : split) {
			String[] pair = line.split(":");
			String key = pair[0].toLowerCase();
			if (key.equals("n"))
				retVal.put("name", pair[1]);
			retVal.put(key, pair[1]);
		}
	}

	private void parseCalendar(HashMap<String, Object> retVal, String contents) {
		String[] split = contents.split("\\r\\n");
		for (String line : split) {
			if (line.startsWith("BEGIN:") || line.startsWith("END:") || line.equals("_")) {
				continue;
			}
			String[] pair = line.split(":");
			if (pair.length == 2) {
				retVal.put(pair[0].toLowerCase(), pair[1]);
			}
		}
	}

	private void parseWifi(HashMap<String, Object> retVal, String contents) {
		String parsed = contents.substring(5);
		String[] split = parsed.split(";");
		for (String line : split) {
			if (line.length() == 0) {
				continue;
			}
			String[] pair = line.split(":");
			retVal.put(pair[0].toLowerCase(), pair[1]);
		}
	}
}
