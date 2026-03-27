# Link Google accout error:
Performing hot restart...                                               
Restarted application in 715ms.
I/flutter ( 3054): Firebase initialized successfully.
I/CredManProvService( 3054): GetCredentialResponse returned from framework
D/InsetsController( 3054): hide(ime(), fromIme=false)
I/ImeTracker( 3054): com.example.watchlistgo:d911c9ab: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
W/System  ( 3054): Ignoring header X-Firebase-Locale because its value was null.
W/System  ( 3054): Ignoring header X-Firebase-Locale because its value was null.
D/FirebaseAuth( 3054): Notifying id token listeners about user ( j0FNi3NfagbuyQdlOUNaKc1moGt1 ).
D/FirebaseAuth( 3054): Notifying auth state listeners about user ( j0FNi3NfagbuyQdlOUNaKc1moGt1 ).
W/DynamiteModule( 3054): Local module descriptor class for com.google.android.gms.providerinstaller.dynamite not found.
I/DynamiteModule( 3054): Considering local module com.google.android.gms.providerinstaller.dynamite:0 and remote module com.google.android.gms.providerinstaller.dynamite:0
W/ProviderInstaller( 3054): Failed to load providerinstaller module: No acceptable module com.google.android.gms.providerinstaller.dynamite found. Local version is 0 and remote version is 0.
I/ple.watchlistgo( 3054): AssetManager2(0x7a6784207538) locale list changing from [] to [en-US]
D/ApplicationLoaders( 3054): Returning zygote-cached class loader: /system/framework/org.apache.http.legacy.jar
D/ApplicationLoaders( 3054): Returning zygote-cached class loader: /system/framework/com.android.media.remotedisplay.jar     
D/ApplicationLoaders( 3054): Returning zygote-cached class loader: /system/framework/com.android.location.provider.jar       
D/ApplicationLoaders( 3054): Returning zygote-cached class loader: /system_ext/framework/androidx.window.extensions.jar      
D/ApplicationLoaders( 3054): Returning zygote-cached class loader: /system_ext/framework/androidx.window.sidecar.jar
D/nativeloader( 3054): InitLlndkLibrariesProduct: libEGL.so:libGLESv1_CM.so:libGLESv2.so:libGLESv3.so:libRS.so:libandroid_net.so:libapexsupport.so:libavf.so:libbinder_ndk.so:libc.so:libcgrouprc.so:libclang_rt.asan-x86_64-android.so:libcom.android.tethering.connectivity_native.so:libdl.so:libft2.so:liblog.so:libm.so:libmediandk.so:libnativewindow.so:libneuralnetworks.so:libselinux.so:libsync.so:libvendorsupport.so:libvndksupport.so:libvulkan.so
D/nativeloader( 3054): Configuring product-clns-10 for unbundled product apk /product/priv-app/PrebuiltGmsCore/PrebuiltGmsCore.apk. target_sdk_version=36, uses_libraries=, library_path=/product/priv-app/PrebuiltGmsCore/lib/x86_64:/product/priv-app/PrebuiltGmsCore/PrebuiltGmsCore.apk!/lib/x86_64:/product/lib64:/system/product/lib64, permitted_path=/data:/mnt/expand:/data/user/0/com.google.android.gms:/product/lib64:/system/product/lib64
D/nativeloader( 3054): InitVndkspLibrariesProduct: VNDK is deprecated with product
I/ple.watchlistgo( 3054): Waiting for a blocking GC ClassLinker
I/ple.watchlistgo( 3054): Waiting for a blocking GC ClassLinker
I/ple.watchlistgo( 3054): WaitForGcToComplete blocked ClassLinker on Background for 23.395ms
I/ple.watchlistgo( 3054): Waiting for a blocking GC ClassLinker
I/ple.watchlistgo( 3054): WaitForGcToComplete blocked ClassLinker on ClassLinker for 17.635ms
I/ple.watchlistgo( 3054): hiddenapi: Accessing hidden method Ldalvik/system/VMStack;->getStackClass2()Ljava/lang/Class; (runtime_flags=0, domain=core-platform, api=unsupported) from Lgbdc; (domain=app) using reflection: allowed
I/fkev    ( 3054): Unable to retrieve flag snapshot for com.google.android.gms.providerinstaller#com.example.watchlistgo, using defaults.
E/GoogleApiManager( 3054): Failed to get service from broker.
E/GoogleApiManager( 3054): java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
E/GoogleApiManager( 3054):      at android.os.Parcel.createExceptionOrNull(Parcel.java:3340)
E/GoogleApiManager( 3054):      at android.os.Parcel.createException(Parcel.java:3324)
E/GoogleApiManager( 3054):      at android.os.Parcel.readException(Parcel.java:3307)
E/GoogleApiManager( 3054):      at android.os.Parcel.readException(Parcel.java:3249)
E/GoogleApiManager( 3054):      at aywi.a(:com.google.android.gms@252635038@25.26.35 (260800-783060121):36)
E/GoogleApiManager( 3054):      at ayup.z(:com.google.android.gms@252635038@25.26.35 (260800-783060121):143)
E/GoogleApiManager( 3054):      at aybo.run(:com.google.android.gms@252635038@25.26.35 (260800-783060121):42)
E/GoogleApiManager( 3054):      at android.os.Handler.handleCallback(Handler.java:995)
E/GoogleApiManager( 3054):      at android.os.Handler.dispatchMessage(Handler.java:103)
E/GoogleApiManager( 3054):      at cirt.mw(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
E/GoogleApiManager( 3054):      at cirt.dispatchMessage(:com.google.android.gms@252635038@25.26.35 (260800-783060121):5)
E/GoogleApiManager( 3054):      at android.os.Looper.loopOnce(Looper.java:248)
E/GoogleApiManager( 3054):      at android.os.Looper.loop(Looper.java:338)
E/GoogleApiManager( 3054):      at android.os.HandlerThread.run(HandlerThread.java:85)
W/FlagRegistrar( 3054): Failed to register com.google.android.gms.providerinstaller#com.example.watchlistgo
W/FlagRegistrar( 3054): fkfh: 17: 17: API: Phenotype.API is not available on this device. Connection failed with: ConnectionResult{statusCode=DEVELOPER_ERROR, resolution=null, message=null}
W/FlagRegistrar( 3054):         at fkfj.a(:com.google.android.gms@252635038@25.26.35 (260800-783060121):13)
W/FlagRegistrar( 3054):         at ggap.d(:com.google.android.gms@252635038@25.26.35 (260800-783060121):3)
W/FlagRegistrar( 3054):         at ggar.run(:com.google.android.gms@252635038@25.26.35 (260800-783060121):130)
W/FlagRegistrar( 3054):         at ggcy.execute(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
W/FlagRegistrar( 3054):         at ggaz.f(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
W/FlagRegistrar( 3054):         at ggaz.m(:com.google.android.gms@252635038@25.26.35 (260800-783060121):99)
W/FlagRegistrar( 3054):         at ggaz.r(:com.google.android.gms@252635038@25.26.35 (260800-783060121):17)
W/FlagRegistrar( 3054):         at fcog.hJ(:com.google.android.gms@252635038@25.26.35 (260800-783060121):35)
W/FlagRegistrar( 3054):         at eqsv.run(:com.google.android.gms@252635038@25.26.35 (260800-783060121):12)
W/FlagRegistrar( 3054):         at ggcy.execute(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
W/FlagRegistrar( 3054):         at eqsw.b(:com.google.android.gms@252635038@25.26.35 (260800-783060121):18)
W/FlagRegistrar( 3054):         at eqtl.b(:com.google.android.gms@252635038@25.26.35 (260800-783060121):36)
W/FlagRegistrar( 3054):         at eqtn.d(:com.google.android.gms@252635038@25.26.35 (260800-783060121):25)
W/FlagRegistrar( 3054):         at axyx.c(:com.google.android.gms@252635038@25.26.35 (260800-783060121):9)
W/FlagRegistrar( 3054):         at aybm.q(:com.google.android.gms@252635038@25.26.35 (260800-783060121):48)
W/FlagRegistrar( 3054):         at aybm.d(:com.google.android.gms@252635038@25.26.35 (260800-783060121):10)
W/FlagRegistrar( 3054):         at aybm.g(:com.google.android.gms@252635038@25.26.35 (260800-783060121):185)
W/FlagRegistrar( 3054):         at aybm.onConnectionFailed(:com.google.android.gms@252635038@25.26.35 (260800-783060121):2)  
W/FlagRegistrar( 3054):         at aybo.run(:com.google.android.gms@252635038@25.26.35 (260800-783060121):70)
W/FlagRegistrar( 3054):         at android.os.Handler.handleCallback(Handler.java:995)
W/FlagRegistrar( 3054):         at android.os.Handler.dispatchMessage(Handler.java:103)
W/FlagRegistrar( 3054):         at cirt.mw(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
W/FlagRegistrar( 3054):         at cirt.dispatchMessage(:com.google.android.gms@252635038@25.26.35 (260800-783060121):5)     
W/FlagRegistrar( 3054):         at android.os.Looper.loopOnce(Looper.java:248)
W/FlagRegistrar( 3054):         at android.os.Looper.loop(Looper.java:338)
W/FlagRegistrar( 3054):         at android.os.HandlerThread.run(HandlerThread.java:85)
W/FlagRegistrar( 3054): Caused by: axxl: 17: API: Phenotype.API is not available on this device. Connection failed with: ConnectionResult{statusCode=DEVELOPER_ERROR, resolution=null, message=null}
W/FlagRegistrar( 3054):         at ayub.a(:com.google.android.gms@252635038@25.26.35 (260800-783060121):15)
W/FlagRegistrar( 3054):         at axza.a(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
W/FlagRegistrar( 3054):         at axyx.c(:com.google.android.gms@252635038@25.26.35 (260800-783060121):5)
W/FlagRegistrar( 3054):         ... 12 more
D/nativeloader( 3054): Load /product/priv-app/PrebuiltGmsCore/PrebuiltGmsCore.apk!/lib/x86_64/libconscrypt_gmscore_jni.so using class loader ns product-clns-10 (caller=/product/priv-app/PrebuiltGmsCore/PrebuiltGmsCore.apk): ok
V/NativeCrypto( 3054): Registering com/google/android/gms/org/conscrypt/NativeCrypto's 315 native methods...
I/ple.watchlistgo( 3054): hiddenapi: Accessing hidden method Ljava/security/spec/ECParameterSpec;->getCurveName()Ljava/lang/String; (runtime_flags=0, domain=core-platform, api=unsupported) from Lcom/google/android/gms/org/conscrypt/Platform; (domain=app) using reflection: allowed
I/ProviderInstaller( 3054): Installed default security provider GmsCore_OpenSSL
I/ple.watchlistgo( 3054): hiddenapi: Accessing hidden field Ljava/net/Socket;->impl:Ljava/net/SocketImpl; (runtime_flags=0, domain=core-platform, api=unsupported) from Lcom/google/android/gms/org/conscrypt/Platform; (domain=app) using reflection: allowed
I/ple.watchlistgo( 3054): hiddenapi: Accessing hidden method Ljava/security/spec/ECParameterSpec;->setCurveName(Ljava/lang/String;)V (runtime_flags=0, domain=core-platform, api=unsupported) from Lcom/google/android/gms/org/conscrypt/Platform; (domain=app) using reflection: allowed
W/Firestore( 3054): (26.1.0) [Firestore]: Listen for QueryWrapper(query=Query(target=Query(users/j0FNi3NfagbuyQdlOUNaKc1moGt1 order by __name__);limitType=LIMIT_TO_FIRST)) failed: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
E/GoogleApiManager( 3054): Failed to get service from broker. 
E/GoogleApiManager( 3054): java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
E/GoogleApiManager( 3054):      at android.os.Parcel.createExceptionOrNull(Parcel.java:3340)
E/GoogleApiManager( 3054):      at android.os.Parcel.createException(Parcel.java:3324)
E/GoogleApiManager( 3054):      at android.os.Parcel.readException(Parcel.java:3307)
E/GoogleApiManager( 3054):      at android.os.Parcel.readException(Parcel.java:3249)
E/GoogleApiManager( 3054):      at aywi.a(:com.google.android.gms@252635038@25.26.35 (260800-783060121):36)
E/GoogleApiManager( 3054):      at ayup.z(:com.google.android.gms@252635038@25.26.35 (260800-783060121):143)
E/GoogleApiManager( 3054):      at aybo.run(:com.google.android.gms@252635038@25.26.35 (260800-783060121):42)
E/GoogleApiManager( 3054):      at android.os.Handler.handleCallback(Handler.java:995)
E/GoogleApiManager( 3054):      at android.os.Handler.dispatchMessage(Handler.java:103)
E/GoogleApiManager( 3054):      at cirt.mw(:com.google.android.gms@252635038@25.26.35 (260800-783060121):1)
E/GoogleApiManager( 3054):      at cirt.dispatchMessage(:com.google.android.gms@252635038@25.26.35 (260800-783060121):5)     
E/GoogleApiManager( 3054):      at android.os.Looper.loopOnce(Looper.java:248)
E/GoogleApiManager( 3054):      at android.os.Looper.loop(Looper.java:338)
E/GoogleApiManager( 3054):      at android.os.HandlerThread.run(HandlerThread.java:85)