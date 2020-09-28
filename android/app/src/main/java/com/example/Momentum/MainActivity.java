package com.example.Momentum;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.MethodChannel;

import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.os.Build.VERSION_CODES;
import android.os.Environment;
import android.util.Log;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;

public class MainActivity extends FlutterActivity {
    private interface AudioDecoderListeners {
        void onDataConsumed();
    }

    private static final String INPUT_METHOD_CHANNEL = "samples.flutter.dev/input_method";
    private static final String OUTPUT_CHANNEL = "samples.flutter.dev/output";
    private AudioDecoderListeners decoderListeners = () -> {};

    private BasicMessageChannel<byte[]> OutputChannel;

    class AudioDecoder {
        String AudioPath;

        AudioDecoder(String AudioPath, AudioDecoderListeners onDataConsumed) {
            this.AudioPath = AudioPath;
        }

        @RequiresApi(api = VERSION_CODES.LOLLIPOP)
        private void startDecoder(String Path) {
            MediaCodec codec = null;
            try {
                codec = MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_AUDIO_MPEG);
            } catch (IOException e) {
                // todo add wrong codec error
                e.printStackTrace();
            }

            MediaExtractor extractor = new MediaExtractor();
            try {
                extractor.setDataSource(Environment.getExternalStorageDirectory() + Path);
            } catch (IOException e) {
                // todo add file not found error
                e.printStackTrace();
            }
            MediaFormat format = extractor.getTrackFormat(0);
            extractor.selectTrack(0);

            MediaCodec finalCodec = codec;
            assert codec != null;
            codec.setCallback(new MediaCodec.Callback() {

                @Override
                public void onInputBufferAvailable(@NonNull final MediaCodec mediaCodec, final int inputBufferId) {
                    ByteBuffer buffer = finalCodec.getInputBuffer(inputBufferId);
                    assert buffer != null;
                    int sampleSize = extractor.readSampleData(buffer, 0);
                    if (sampleSize < 0) {
                        mediaCodec.queueInputBuffer(inputBufferId, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM);
                    } else {
                        mediaCodec.queueInputBuffer(inputBufferId, 0, sampleSize, extractor.getSampleTime(), 0);
                        extractor.advance();
                    }
                }

                @Override
                public void onOutputBufferAvailable(@NonNull final MediaCodec mediaCodec, final int outputBufferId,
                        @NonNull final MediaCodec.BufferInfo bufferInfo) {
                    ByteBuffer outputBuffer = finalCodec.getOutputBuffer(outputBufferId);
                    assert outputBuffer != null;

                    byte[] bufferArray = new byte[outputBuffer.remaining()];
                    try {
                        outputBuffer.get(bufferArray);
                    } catch (Exception e) {
                        Log.e("Exception", "outputBuffer.get(bufferArray)", e);
                    }

                    OutputChannel.send(bufferArray);

                    decoderListeners = () -> {
					    Log.e("onDataConsumed","Consumed");
					    finalCodec.releaseOutputBuffer(outputBufferId,true);
					};
                }

                @Override
                public void onError(@NonNull final MediaCodec mediaCodec, @NonNull final MediaCodec.CodecException e) {

                }

                @Override
                public void onOutputFormatChanged(@NonNull final MediaCodec mediaCodec,
                        @NonNull final MediaFormat mediaFormat) {

                }
            });
            codec.configure(format, null, null, 0);
            codec.start();
        }

        void start() {
            final AudioDecoder _this = this;
            new Thread() {
                @RequiresApi(api = VERSION_CODES.LOLLIPOP)
                @Override
                public void run() {
                    _this.startDecoder(_this.AudioPath);
                }
            }.start();
        }
    }

    @RequiresApi(api = VERSION_CODES.LOLLIPOP)
    @Override
    public void configureFlutterEngine(@NonNull final FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        OutputChannel = new BasicMessageChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), OUTPUT_CHANNEL,
                io.flutter.plugin.common.StandardMessageCodec.INSTANCE);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), INPUT_METHOD_CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    // Note: this method is invoked on the main thread.
                    if (call.method.equals("getSoundData")) {
                        new AudioDecoder(((ArrayList<String>) call.arguments).get(0), decoderListeners).start();
                    } else if (call.method.equals("dataConsumed")) {
                        decoderListeners.onDataConsumed();
                    }
                });
    }
}
