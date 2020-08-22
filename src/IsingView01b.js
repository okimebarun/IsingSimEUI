/*
title: IsingSimEUI( manipulatable Ising model simulation with Electron UI ) 
version: 1.0
date: 2020/08/12
author: okimebarun
url: https://github.com/okimebarun/
url: https://qiita.com/oki_mebarun/
*/

//////////////////////////////////////////////////////////////////
// 
window.addEventListener('load', init);

function init() {
	//
	drawbox01 = new DrawBox("myCanvas01");
	drawbox02 = new DrawBox("myCanvas02");
	ctlinfo = new ControlInfo();
	animator = new Animator();
	trajectory = new Trajectory();

	//
	slider01changed(1);
	slider02changed(0);
	//
}

async function slider01changed(v) {
	const range01  = document.getElementById("range01");
	const lrange01 = document.getElementById("lrange01");
	
	ctlinfo.T = v;
	lrange01.textContent = "T= "+v;
	sendMessageToJulia('T: '+v);
}

async function slider02changed(v) {
	const range02  = document.getElementById("range02");
	const lrange02 = document.getElementById("lrange02");
	
	ctlinfo.H = v;
	lrange02.textContent = "H= "+v;
	sendMessageToJulia('H: '+v);
}


//////////////////////////////////////////////////////////////////

class DrawBox {
	constructor(canvasId) {
		this.canvas = document.getElementById(canvasId);
		this.ctx = this.canvas.getContext('2d');
		//
		this.rminx = 0;
		this.rmaxx = this.canvas.width;
		this.rminy = 0;
		this.rmaxy = this.canvas.height;
	}
	//
	setrange(minx, maxx, miny, maxy)
	{
		this.rminx = minx;
		this.rmaxx = maxx;
		this.rminy = miny;
		this.rmaxy = maxy;
	}
	//
	convpx(x)
	{
		return Math.floor(this.canvas.width * ( x - this.rminx ) / (this.rmaxx - this.rminx));
	}
	convpy(y)
	{
		return Math.floor(this.canvas.height * ( this.rmaxy - y ) / (this.rmaxy - this.rminy));
	}
	clear() {
		var ctx    = this.ctx;
		var canvas = this.canvas;
		
		ctx.clearRect(0, 0, canvas.width, canvas.height);
	}
	drawPoly02(poly, ndiv ) {
		//poly : [x,y, x,y, x,y.....];
		var ctx    = this.ctx;
		var canvas = this.canvas;

		ctx.strokeStyle = '#fff';
		ctx.fillStyle = '#f00';

		ctx.beginPath();
		ctx.moveTo( this.convpx(poly[0]), this.convpy(poly[1]) );
		for(var item=2 ; item < poly.length-1 ; item+=2 ){
			if (item % (ndiv*2) == 0) {
				ctx.closePath();
				ctx.fill();
				ctx.beginPath();
				ctx.moveTo( this.convpx(poly[item]) , this.convpy(poly[item+1]) );
			} else {
				ctx.lineTo( this.convpx(poly[item]) , this.convpy(poly[item+1]) );
			}
		}

		ctx.closePath();
		ctx.fill();
		ctx.stroke();
	}
	drawLine( points ) {
		var ctx    = this.ctx;
		var canvas = this.canvas;
		
		ctx.clearRect(0, 0, canvas.width, canvas.height);
		
		ctx.strokeStyle = '#f00';

		ctx.beginPath();
		ctx.moveTo( this.convpx(points[0]), this.convpy(points[1]) );
		for(var item=2 ; item < points.length-1 ; item+=2 ){
			ctx.lineTo( this.convpx(points[item]) , this.convpy(points[item+1]) );
		}

		ctx.stroke();
	}
}

class ControlInfo {
	constructor() {
		this.T = 1;
		this.H = 1;
	}
	toString() {
		return "T:" + this.T + ",H:" + this.H;
	}
}

class Trajectory {
	constructor() {
		this.maxn = 100;
		this.num = 0;
		this.xys = [];
	}
	add(x, y) {
		this.xys.push(x);
		this.xys.push(y);
		if (this.xys.length > 2*this.maxn) {
			this.xys.shift();
			this.xys.shift();
		}
	}
	
}

class Animator {
	constructor() {
		this.sleep = 800; // [ms]
	}
	start() {
		this.timerId = setInterval(this.update, this.sleep);
	}
	stop() {
		clearInterval(this.timerId);
	}
	update() {
		console.log("ctlinfo: " + ctlinfo.toString());
		drawbox02.drawLine(trajectory.xys);
		sendMessageToJulia('calc T:'+ctlinfo.T+' H:' +ctlinfo.H);
	}
}

