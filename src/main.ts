import {vec3} from 'gl-matrix';
import Stats from 'stats-js';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import lambertVertSource from './shaders/lambert-vert.glsl?raw';
import lambertFragSource from './shaders/lambert-frag.glsl?raw';
import skyVertSource from './shaders/sky-vert.glsl?raw';
import skyFragSource from './shaders/sky-frag.glsl?raw';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  speed: 5.0,
  octaves: 6,
  waveStrength: 1.0,
  tailLength: 1.0,
  coolColor: [255, 14, 0],
  middleColor: [255, 77, 0],
  hotColor: [255, 247, 31],
  skyBottomColor: [6, 6, 35],
  skyTopColor: [0, 0, 0],
  starDensity: 0.25,
  'Reset Defaults': resetDefaults,
  'Load Scene': loadScene, // A function pointer, essentially
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = 5;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function resetDefaults() {
  controls.tesselations = 5;
  controls.speed = 5.0;
  controls.octaves = 6;
  controls.waveStrength = 1.0;
  controls.tailLength = 1.0;
  controls.coolColor = [255, 14, 0];
  controls.middleColor = [255, 77, 0];
  controls.hotColor = [255, 247, 31];
  controls.skyBottomColor = [6, 6, 35];
  controls.skyTopColor = [0, 0, 0];
  controls.starDensity = 0.25;
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'speed', 0, 10).step(0.1);
  gui.add(controls, 'octaves', 1, 10).step(1);
  gui.add(controls, 'waveStrength', 0, 2).step(0.1);
  gui.add(controls, 'tailLength', 0, 2).step(0.1);
  gui.addColor(controls, 'coolColor');
  gui.addColor(controls, 'middleColor');
  gui.addColor(controls, 'hotColor');
  gui.addColor(controls, 'skyBottomColor').listen();
  gui.addColor(controls, 'skyTopColor').listen();
  gui.add(controls, 'starDensity', 0, 1).step(0.01).listen();
  gui.add(controls, 'Reset Defaults');
  gui.add(controls, 'Load Scene');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, lambertVertSource),
    new Shader(gl.FRAGMENT_SHADER, lambertFragSource),
  ]);

  const sky = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, skyVertSource),
    new Shader(gl.FRAGMENT_SHADER, skyFragSource),
  ]);

  let totalTime = 0;
  let pervTime = performance.now();
  // This function will be called every frame
  function tick() {
    const now = performance.now();
    totalTime += Math.min((now - pervTime) / 1000, 0.1) * controls.speed;
    pervTime = now;
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    gl.disable(gl.DEPTH_TEST);
    gl.depthMask(false);
    sky.setTime(totalTime);
    sky.setSkyBottomColor(controls.skyBottomColor);
    sky.setSkyTopColor(controls.skyTopColor);
    sky.setStarDensity(controls.starDensity);
    sky.draw(square);
    gl.depthMask(true);
    gl.enable(gl.DEPTH_TEST);
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    lambert.setTime(totalTime);
    lambert.setOctaves(controls.octaves);
    lambert.setWaveStrength(controls.waveStrength);
    lambert.setTailLength(controls.tailLength);
    lambert.setCoolColor(controls.coolColor);
    lambert.setMiddleColor(controls.middleColor);
    lambert.setHotColor(controls.hotColor);
    renderer.render(camera, lambert, [
      icosphere,
      // square,
    ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
