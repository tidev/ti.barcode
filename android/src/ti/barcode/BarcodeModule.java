/**
 * Ti.Barcode Module
 * Copyright (c) 2010-2019 by Appcelerator, Inc. All Rights Reserved.
 * Please see the LICENSE included with this distribution for details.
 */

package ti.barcode;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.ResultPoint;
import com.google.zxing.client.android.CaptureActivity;
import com.google.zxing.client.android.Intents;
import com.google.zxing.client.android.camera.CameraConfigurationManager;
import com.google.zxing.client.result.ParsedResult;
import com.google.zxing.client.result.ResultParser;
import com.google.zxing.common.HybridBinarizer;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.TiBlob;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiActivityResultHandler;
import org.appcelerator.titanium.util.TiActivitySupport;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.view.TiDrawableReference;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.util.Log;
import ti.modules.titanium.BufferProxy;
import ti.modules.titanium.codec.CodecModule;

@Kroll.module(name = "Barcode", id = "ti.barcode", propertyAccessors = { "displayedMessage", "allowRotation" })
public class BarcodeModule extends KrollModule implements TiActivityResultHandler
{

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
	public static final int FORMAT_CODE_93 = 9;
	@Kroll.constant
	public static final int FORMAT_CODE_39_MOD_43 = 8; // TODO: Remove, same as FORMAT_CODE_39
	@Kroll.constant
	public static final int FORMAT_ITF = 11;
	@Kroll.constant
	public static final int FORMAT_INTERLEAVED_2_OF_5 = 11; // TODO: Remove, same as FORMAT_ITF
	@Kroll.constant
	public static final int FORMAT_PDF_417 = 12;
	@Kroll.constant
	public static final int FORMAT_AZTEC = 13;
	@Kroll.constant
	public static final int FORMAT_RSS_14 = 14;
	@Kroll.constant
	public static final int FORMAT_MAXICODE = 15;
	@Kroll.constant
	public static final int FORMAT_CODABAR = 16;
	@Kroll.constant
	public static final int FORMAT_RSS_EXPANDED = 17;

	private static final List<String> FORMAT_STRINGS =
		Arrays.asList("NONE", "QR_CODE", "DATA_MATRIX", "UPC_E", "UPC_A", "EAN_8", "EAN_13", "CODE_128", "CODE_39",
					  "CODE_93", "CODE_39", "ITF", "PDF_417", "AZTEC", "RSS_14", "MAXICODE", "CODABAR", "RSS_EXPANDED");

	public BarcodeModule()
	{
		super();

		defaultValues.put("allowRotation", false);
		defaultValues.put("allowMenu", true);
		defaultValues.put("allowInstructions", true);
		defaultValues.put("useFrontCamera", false);
		defaultValues.put("useLED", false);
	}

	private static BarcodeModule _instance;

	public static BarcodeModule getInstance()
	{
		return _instance;
	}

	// Methods

	@Kroll.method
	public void cancel()
	{
		_instance = null;
		CaptureActivity.getInstance().cancel();
	}

	// clang-format off
	@Kroll.method
	@Kroll.getProperty
	public boolean getUseFrontCamera()
	// clang-format on
	{
		return new CameraConfigurationManager(getActivity()).getFrontCamera();
	}

	// clang-format off
	@Kroll.method
	@Kroll.setProperty
	public void setUseFrontCamera(boolean value)
	// clang-format on
	{
		new CameraConfigurationManager(getActivity()).setFrontCamera(value);
		CaptureActivity activity = CaptureActivity.getInstance();
		if (activity != null) {
			activity.getCameraManager().setManualCameraId(FrontCamera.getFrontCamera());
			activity.reset();
		}
	}

	// clang-format off
	@Kroll.method
	@Kroll.getProperty
	public boolean getUseLED()
	// clang-format on
	{
		CaptureActivity activity = CaptureActivity.getInstance();
		if (activity != null) {
			return activity.getCameraManager().getTorch();
		}
		return false;
	}

	// clang-format off
	@Kroll.method
	@Kroll.setProperty
	public void setUseLED(boolean value)
	// clang-format on
	{
		new CameraConfigurationManager(getActivity()).setTorch(null, value);
		CaptureActivity activity = CaptureActivity.getInstance();
		if (activity != null) {
			activity.getCameraManager().setTorch(value);
		}
	}

	@SuppressWarnings("rawtypes")
	private Map<DecodeHintType, Object> populateHints(HashMap args)
	{
		Hashtable<DecodeHintType, Object> hints = new Hashtable<DecodeHintType, Object>();
		if (args.containsKey("acceptedFormats")) {
			Object[] acceptedFormats = (Object[]) args.get("acceptedFormats");
			if (acceptedFormats.length > 0) {
				Vector<BarcodeFormat> decodeFormats = new Vector<BarcodeFormat>();
				for (Object acceptedFormat : acceptedFormats) {
					decodeFormats.add(BarcodeFormat.valueOf(FORMAT_STRINGS.get(TiConvert.toInt(acceptedFormat))));
				}
				hints.put(DecodeHintType.POSSIBLE_FORMATS, decodeFormats);
			}
		}
		// Allow setting "tryHarder"
		if (args.containsKey("tryHarder") && TiConvert.toBoolean(args.get("tryHarder"))) {
			hints.put(DecodeHintType.TRY_HARDER, true);
		}

		// Allow setting "pureBarcode"
		if (args.containsKey("pureBarcode") && TiConvert.toBoolean(args.get("pureBarcode"))) {
			hints.put(DecodeHintType.PURE_BARCODE, true);
		}

		// Allow setting "assumeGS1"
		if (args.containsKey("assumeGS1") && TiConvert.toBoolean(args.get("assumeGS1"))) {
			hints.put(DecodeHintType.ASSUME_GS1, true);
		}

		// RETURN_CODABAR_START_END Boolean
		if (args.containsKey("returnCodabarStartEnd") && TiConvert.toBoolean(args.get("returnCodabarStartEnd"))) {
			hints.put(DecodeHintType.RETURN_CODABAR_START_END, true);
		}

		// ASSUME_CODE_39_CHECK_DIGIT Boolean
		if (args.containsKey("assumeCode39CheckDigit") && TiConvert.toBoolean(args.get("assumeCode39CheckDigit"))) {
			hints.put(DecodeHintType.ASSUME_CODE_39_CHECK_DIGIT, true);
		}

		// CHARACTER_SET String
		if (args.containsKey("characterSet")) {
			hints.put(DecodeHintType.CHARACTER_SET, TiConvert.toString(args.get("characterSet")));
		}

		// ALLOWED_LENGTHS int[]
		if (args.containsKey("allowedLengths")) {
			Object[] allowedLengths = (Object[]) args.get("allowedLengths");
			if (allowedLengths.length > 0) {
				int[] allowedLengthArray = new int[allowedLengths.length];
				int i = 0;
				for (Object allowedLength : allowedLengths) {
					allowedLengthArray[i++] = TiConvert.toInt(allowedLength);
				}
				hints.put(DecodeHintType.ALLOWED_LENGTHS, allowedLengthArray);
			}
		}

		// ALLOWED_EAN_EXTENSIONS int[]
		if (args.containsKey("allowedEANExtensions")) {
			Object[] allowedEANExtensions = (Object[]) args.get("allowedEANExtensions");
			if (allowedEANExtensions.length > 0) {
				int[] eanExtensions = new int[allowedEANExtensions.length];
				int i = 0;
				for (Object eanExtension : allowedEANExtensions) {
					eanExtensions[i++] = TiConvert.toInt(eanExtension);
				}
				hints.put(DecodeHintType.ALLOWED_EAN_EXTENSIONS, eanExtensions);
			}
		}
		return hints;
	}

	@Kroll.method
	@SuppressWarnings({ "rawtypes" })
	public void parse(@Kroll.argument(optional = false) HashMap args)
	{
		_instance = this;

		try {

			TiBlob blob = (TiBlob) args.get("image");
			TiDrawableReference ref = TiDrawableReference.fromBlob(TiApplication.getAppCurrentActivity(), blob);
			Bitmap image = ref.getBitmap();

			int w = image.getWidth(), h = image.getHeight();
			int[] rgb = new int[w * h];
			image.getPixels(rgb, 0, w, 0, 0, w, h);
			LuminanceSource source = new RGBLuminanceSource(w, h, rgb);

			BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));
			MultiFormatReader reader = new MultiFormatReader();

			Result rawResult = reader.decode(bitmap, populateHints(args));
			String format = rawResult.getBarcodeFormat().toString();
			String result = rawResult.toString();
			processResult(format, result, rawResult.getRawBytes(), Activity.RESULT_OK);

		} catch (NotFoundException e) {
			HashMap<String, Object> errdict = new HashMap<String, Object>();
			errdict.put("message", "Scan Failed");
			errdict.put("exception", e.toString());
			fireEvent("error", errdict);
		}
	}

	@Kroll.method
	@SuppressWarnings({ "rawtypes", "unchecked" })
	public void capture(@Kroll.argument(optional = true) HashMap args)
	{
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

			Map<DecodeHintType, Object> hints = populateHints(args);
			// character set and possible formats are specified differently for intent...
			if (hints.containsKey(DecodeHintType.CHARACTER_SET)) {
				intent.putExtra(Intents.Scan.CHARACTER_SET, (String) hints.get(DecodeHintType.CHARACTER_SET));
			}
			if (args.containsKey("acceptedFormats")) {
				Object[] acceptedFormats = (Object[]) args.get("acceptedFormats");
				if (acceptedFormats.length > 0) {
					String formats = "";
					for (Object acceptedFormat : acceptedFormats) {
						formats += FORMAT_STRINGS.get(TiConvert.toInt(acceptedFormat)) + ",";
					}
					Log.d(LCAT, formats.substring(0, formats.length() - 1));
					intent.putExtra(Intents.Scan.FORMATS, formats.substring(0, formats.length() - 1));
				}
			}

			intent.putExtra(Intents.Scan.SHOW_RECTANGLE, argsDict.optBoolean("showRectangle", true));
			intent.putExtra(Intents.Scan.KEEP_OPEN, argsDict.optBoolean("keepOpen", false));
			intent.putExtra(Intents.Scan.SHOW_CANCEL, argsDict.optBoolean("showCancel", true));
			frameWidth = argsDict.optInt("frameWidth", 0);
			frameHeight = argsDict.optInt("frameHeight", 0);
			intent.putExtra(Intents.Scan.SHOW_INFO_TEXT, argsDict.optBoolean("showInfoText", false));
			intent.putExtra(Intents.Scan.PREVENT_ROTATION, argsDict.optBoolean("preventRotation", true));
		} else {
			Intents.Scan.overlayProxy = null;
			intent.putExtra(Intents.Scan.SHOW_RECTANGLE, true);
			intent.putExtra(Intents.Scan.SHOW_CANCEL, true);
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
	public void onError(Activity activity, int requestCode, Exception e)
	{
		HashMap<String, Object> errdict = new HashMap<String, Object>();
		errdict.put("message", "Scan Failed");
		errdict.put("code", requestCode);
		fireEvent("error", errdict);
	}

	public void processFailed(int resultCode)
	{
		Log.w(LCAT, "Result for scan was not OK: " + Activity.RESULT_CANCELED);
		// for (String key : data.getExtras().keySet()) { Log.d(LCAT, "intent extra: " + key + ", value: " + data.getExtras().get(key)); }
		HashMap<String, Object> errdict = new HashMap<String, Object>();
		errdict.put("message", "Scan Failed");
		errdict.put("code", resultCode);
		fireEvent("error", errdict);
	}

	public void processCanceled(int resultCode)
	{
		Log.w(LCAT, "Result for scan was CANCELED");
		HashMap<String, Object> cancelDict = new HashMap<String, Object>();
		cancelDict.put("message", "Scan Canceled");
		cancelDict.put("code", resultCode);
		fireEvent("cancel", cancelDict);
	}

	public void processResult(String format, String contents, byte[] bytes, int resultCode)
	{
		int contentType = getContentType(format, contents);
		HashMap<String, Object> dict = new HashMap<String, Object>();
		int formatIndex = FORMAT_STRINGS.indexOf(format);
		if (formatIndex != -1) {
			dict.put("format", formatIndex);
		} else {
			// format not in our FORMAT_STRINGS array!
			dict.put("format", format);
		}
		dict.put("result", contents);
		dict.put("code", resultCode);
		dict.put("contentType", contentType);
		dict.put("data", parseData(contentType, contents));
		BufferProxy buffer = null;
		if (bytes != null && bytes.length > 0) {
			buffer = new BufferProxy(bytes);
		} else {
			buffer = new BufferProxy(); // 0-length empty buffer/array
		}
		buffer.setProperty(TiC.PROPERTY_BYTE_ORDER, CodecModule.getByteOrder(null));
		dict.put("bytes", buffer);
		fireEvent("success", dict);
	}

	@Override
	public void onResult(Activity activity, int requestCode, int resultCode, Intent data)
	{
		if (resultCode != Activity.RESULT_OK && resultCode != Activity.RESULT_CANCELED) {
			processFailed(resultCode);
			return;
		} else if (resultCode == Activity.RESULT_CANCELED) {
			processCanceled(resultCode);
			return;
		}

		try {
			processResult(data.getStringExtra(Intents.Scan.RESULT_FORMAT), data.getStringExtra(Intents.Scan.RESULT),
						  data.getByteArrayExtra(Intents.Scan.RESULT_BYTES), resultCode);
		} catch (Exception e) {
			Log.e(LCAT, "Hit exception while processing barcode! " + e.toString());
			e.printStackTrace();
			processFailed(resultCode);
		}

		if (!keepOpen) {
			_instance = null;
		}
	}

	private int getContentType(String format, String contents)
	{
		if (format.equals("QR_CODE")) {
			ParsedResult res =
				ResultParser.parseResult(new Result(contents, new byte[0], new ResultPoint[0], BarcodeFormat.QR_CODE));
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

	private HashMap<String, Object> parseData(int contentType, String contents)
	{
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

	private void parseGeo(HashMap<String, Object> retVal, String contents)
	{
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

	private void parseSMS(HashMap<String, Object> retVal, String contents)
	{
		String parsed = contents.substring(6);
		if (parsed.contains(":")) {
			String[] split = parsed.split(":");
			retVal.put("phonenumber", split[0]);
			retVal.put("message", split[1]);
		} else {
			retVal.put("phonenumber", parsed);
		}
	}

	private void parseEmail(HashMap<String, Object> retVal, String contents)
	{
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

	private void parseContact(HashMap<String, Object> retVal, String contents)
	{
		String[] split = contents.substring(7).split(";");
		for (String line : split) {
			String[] pair = line.split(":");
			String key = pair[0].toLowerCase();
			if (key.equals("n"))
				retVal.put("name", pair[1]);
			retVal.put(key, pair[1]);
		}
	}

	private void parseCalendar(HashMap<String, Object> retVal, String contents)
	{
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

	private void parseWifi(HashMap<String, Object> retVal, String contents)
	{
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

	public String getApiName()
	{
		return "Ti.Barcode";
	}
}
