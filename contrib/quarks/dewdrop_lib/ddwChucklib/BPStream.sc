
// reference a stream in a BP environment

// normal behavior is to set the environment when creating the stream
// however -- sometimes you might need to make the stream outside the environment
// in that case you can pass in an environment
// if the envir arg to *new is nil, we set the environment at stream time

BPStream : Pattern {
	var	<>key, <>resetSource, <>envir;
	*new { |key, resetSource = false, envir|
		^super.newCopyArgs(key, resetSource, envir)
	}

	asStream {
		var	streamKey = (key ++ "Stream").asSymbol;
		envir ?? { envir = currentEnvironment; };
		(resetSource or: { envir[streamKey].isNil }).if({
			envir.use({
				streamKey.envirPut(key.asSymbol.envirGet.asStream);
				streamKey.envirGet.isNil.if({
					"Source stream for BPStream(%) is not populated."
						.format(key.asCompileString).warn;
				});
			});
		});
		^FuncStream({ |inval|
			streamKey.envirGet.next(inval)
		}, { this.reset }).envir_(envir)   // make sure FuncStream knows which environment
	}

	reset {
		envir.use { (key ++ "Stream").asSymbol.envirGet.reset }
	}

	printOn { |stream| stream << "BPStream(" <<< key << ")" }
		// not including envir here because it could be an infinitely-recursive data structure
		// (envir contains BPStream, which contains envir etc.)
	storeArgs { ^[key, resetSource] }
//	storeOn { |stream| this.printOn(stream) }
}
