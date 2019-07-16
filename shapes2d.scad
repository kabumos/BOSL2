include<BOSL2/std.scad>
//////////////////////////////////////////////////////////////////////
// LibFile: shapes2d.scad
//   Common useful 2D shapes.
//   To use, add the following lines to the beginning of your file:
//   ```
//   include <BOSL2/std.scad>
//   ```
//////////////////////////////////////////////////////////////////////


// Section: 2D Drawing Helpers

// Module: stroke()
// Usage:
//   stroke(path, width, [endcap], [closed]);
// Description:
//   Draws a 2D line path with a given line thickness.
// Arguments:
//   path = The 2D path to draw along.
//   width = The width of the line to draw.
//   endcaps = If true, draw round endcaps at the ends of the line.
//   closed = If true, draw an additional line from the end of the path to the start.
// Example(2D):
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=10, endcaps=false);
// Example(2D):
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20, endcaps=true);
// Example(2D):
//   path = [[0,100], [100,100], [200,0], [100,-100], [100,0]];
//   stroke(path, width=20, endcaps=true, closed=true);
module stroke(path, width=1, endcaps=true, closed=false)
{
	$fn = quantup(segs(width/2),4);
	path = closed? concat(path,[path[0]]) : path;
	assert(is_list(path) && is_vector(path[0]) && len(path[0])==2, "path must be a 2D list of points.");
	segments = pair(path);
	segpairs = pair(segments);

	// Line segments
	for (seg = segments) {
		delt = seg[1] - seg[0];
		translate(seg[0])
			rot(from=BACK,to=delt)
				left(width/2)
					square([width, norm(delt)], center=false);
	}

	// Joints
	for (segpair = segpairs) {
		seg1 = segpair[0];
		seg2 = segpair[1];
		delt1 = seg1[1] - seg1[0];
		delt2 = seg2[1] - seg2[0];
		hull() {
			translate(seg1[1])
				rot(from=BACK,to=delt1)
					circle(d=width);
			translate(seg2[0])
				rot(from=BACK,to=delt2)
					circle(d=width);
		}
	}

	// Endcaps
	if (endcaps) {
		seg1 = segments[0];
		delt1 = seg1[1] - seg1[0];
		translate(seg1[0])
			rot(from=BACK, to=delt1)
				circle(d=width);
		seg2 = select(segments,-1);
		delt2 = seg2[1] - seg2[0];
		translate(seg2[1])
			rot(from=BACK, to=delt2)
				circle(d=width);
	}
}


// Section: 2D Shapes


// Function&Module: arc()
// Usage: 2D arc from 0º to `angle` degrees.
//   arc(N, r|d, angle);
// Usage: 2D arc from START to END degrees.
//   arc(N, r|d, angle=[START,END])
// Usage: 2D arc from `start` to `start+angle` degrees.
//   arc(N, r|d, start, angle)
// Usage: 2D circle segment by `width` and `thickness`, starting and ending on the X axis.
//   arc(N, width, thickness)
// Usage: Shortest 2D or 3D arc around centerpoint `cp`, starting at P0 and ending on the vector pointing from `cp` to `P1`.
//   arc(N, cp, points=[P0,P1])
// Usage: 2D or 3D arc, starting at `P0`, passing through `P1` and ending at `P2`.
//   arc(N, points=[P0,P1,P2])
// Description:
//   If called as a function, returns a 2D or 3D path forming an arc.
//   If called as a module, creates a 2D arc polygon or pie slice shape.
// Arguments:
//   N = Number of vertices to form the arc curve from.
//   r = Radius of the arc.
//   d = Diameter of the arc.
//   angle = If a scalar, specifies the end angle in degrees.  If a vector of two scalars, specifies start and end angles.
//   cp = Centerpoint of arc.
//   points = Points on the arc.
//   width = If given with `thickness`, arc starts and ends on X axis, to make a circle segment.
//   thickness = If given with `width`, arc starts and ends on X axis, to make a circle segment.
//   start = Start angle of arc.
//   wedge = If true, include centerpoint `cp` in output to form pie slice shape.
// Examples(2D):
//   arc(N=4, r=30, angle=30, wedge=true);
//   arc(r=30, angle=30, wedge=true);
//   arc(d=60, angle=30, wedge=true);
//   arc(d=60, angle=120);
//   arc(d=60, angle=120, wedge=true);
//   arc(r=30, angle=[75,135], wedge=true);
//   arc(r=30, start=45, angle=75, wedge=true);
//   arc(width=60, thickness=20);
//   arc(cp=[-10,5], points=[[20,10],[0,35]], wedge=true);
//   arc(points=[[30,-5],[20,10],[-10,20]], wedge=true);
//   arc(points=[[5,30],[-10,-10],[30,5]], wedge=true);
// Example(2D):
//   path = arc(points=[[5,30],[-10,-10],[30,5]], wedge=true);
//   stroke(closed=true, path);
// Example(FlatSpin):
//   include <BOSL2/paths.scad>
//   path = arc(points=[[0,30,0],[0,0,30],[30,0,0]]);
//   trace_polyline(path, showpts=true, color="cyan");
function arc(N, r, angle, d, cp, points, width, thickness, start, wedge=false) =
	// First try for 2D arc specified by angles
	is_def(width) && is_def(thickness)? (
		arc(N,points=[[width/2,0], [0,thickness], [-width/2,0]],wedge=wedge)
	) : is_def(angle)? (
		let(
			parmok = is_undef(points) && is_undef(width) && is_undef(thickness) &&
				((is_vector(angle) && len(angle)==2 && is_undef(start)) || is_num(angle))
		)
		assert(parmok,"Invalid parameters in arc")
		let(
			cp = is_def(cp) ? cp : [0,0],
			start = is_def(start)? start : is_vector(angle) ? angle[0] : 0,
			angle = is_vector(angle)? angle[1]-angle[0] : angle,
			r = get_radius(r=r,d=d),
			N = max(3, is_undef(N)? ceil(segs(r)*abs(angle)/360) : N),
			arcpoints = [for(i=[0:N-1]) let(theta = start + i*angle/(N-1)) r*[cos(theta),sin(theta)]+cp],
			extra = wedge? [cp] : []
		)
		concat(extra,arcpoints)
	) :
	assert(is_list(points),"Invalid parameters")
	// Arc is 3D, so transform points to 2D and make a recursive call, then remap back to 3D
	len(points[0])==3? (
		let(
			thirdpoint = is_def(cp) ? cp : points[2],
			center2d = is_def(cp) ? project_plane(cp,thirdpoint,points[0],points[1]) : undef,
			points2d = project_plane(points,thirdpoint,points[0],points[1])
		)
		lift_plane(arc(N,cp=center2d,points=points2d,wedge=wedge),thirdpoint,points[0],points[1])
	) : is_def(cp)? (
		// Arc defined by center plus two points, will have radius defined by center and points[0]
		// and extent defined by direction of point[1] from the center
		let(
			angle = vector_angle(points[0], cp, points[1]),
			v1 = points[0]-cp,
			v2 = points[1]-cp,
			dir = sign(det2([v1,v2])),   // z component of cross product
			r=norm(v1)
		)
		assert(dir!=0,"Collinear inputs don't define a unique arc")
		arc(N,cp=cp,r=r,start=atan2(v1.y,v1.x),angle=dir*angle,wedge=wedge)
	) : (
		// Final case is arc passing through three points, starting at point[0] and ending at point[3]
		let(col = collinear(points[0],points[1],points[2],1e-3))
		assert(!col, "Collinear inputs do not define an arc")
		let(
			cp = line_intersection(_normal_segment(points[0],points[1]),_normal_segment(points[1],points[2])),
			// select order to be counterclockwise
			dir = det2([points[1]-points[0],points[2]-points[1]]) > 0,
			points = dir? select(points,[0,2]) : select(points,[2,0]),
			r = norm(points[0]-cp),
			theta_start = atan2(points[0].y-cp.y, points[0].x-cp.x),
			theta_end = atan2(points[1].y-cp.y, points[1].x-cp.x),
			angle = posmod(theta_end-theta_start, 360),
			arcpts = arc(N,cp=cp,r=r,start=theta_start,angle=angle,wedge=wedge)
		)
		dir ? arcpts : reverse(arcpts)
	);


module arc(N, r, angle, d, cp, points, width, thickness, start, wedge=false)
{
	path = arc(N=N, r=r, angle=angle, d=d, cp=cp, points=points, width=width, thickness=thickness, start=start, wedge=wedge);
	polygon(path);
}


function _normal_segment(p1,p2) =
	let(center = (p1+p2)/2)
	[center, center + norm(p1-p2)/2 * line_normal(p1,p2)];


// Function&Module: trapezoid()
// Usage:
//   trapezoid(h, w1, w2);
// Description:
//   When called as a function, returns a 2D path for a trapezoid with parallel front and back sides.
//   When called as a module, creates a 2D trapezoid with parallel front and back sides.
// Arguments:
//   h = The Y axis height of the trapezoid.
//   w1 = The X axis width of the front end of the trapezoid.
//   w2 = The X axis width of the back end of the trapezoid.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   trapezoid(h=30, w1=40, w2=20);
//   trapezoid(h=25, w1=20, w2=35);
//   trapezoid(h=20, w1=40, w2=0);
// Example(2D): Called as Function
//   stroke(closed=true, trapezoid(h=30, w1=40, w2=20));
function trapezoid(h, w1, w2, anchor=CENTER, spin=0) =
	let(
		s = anchor.y>0? [w2,h] : anchor.y<0? [w1,h] : [(w1+w2)/2,h],
		path = [[-w1/2,-h/2], [-w2/2,h/2], [w2/2,h/2], [w1/2,-h/2]]
	) rot(spin, p=move(-vmul(anchor,s/2), p=path));



module trapezoid(h, w1, w2, anchor=CENTER, spin=0)
	polygon(trapezoid(h=h, w1=w1, w2=w2, anchor=anchor, spin=spin));


// Function&Module: regular_ngon()
// Usage:
//   regular_ngon(n, or|od, [realign]);
//   regular_ngon(n, ir|id, [realign]);
//   regular_ngon(n, side, [realign]);
// Description:
//   When called as a function, returns a 2D path for a regular N-sided polygon.
//   When called as a module, creates a 2D regular N-sided polygon.
// Arguments:
//   n = The number of sides.
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   regular_ngon(n=5, or=30);
//   regular_ngon(n=5, od=60);
// Example(2D): by Inner Size
//   regular_ngon(n=5, ir=30);
//   regular_ngon(n=5, id=60);
// Example(2D): by Side Length
//   regular_ngon(n=8, side=20);
// Example(2D): Realigned
//   regular_ngon(n=8, side=20, realign=true);
// Example(2D): Called as Function
//   stroke(closed=true, regular_ngon(n=6, or=30));
function regular_ngon(n=6, or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0) =
	let(
		sc = 1/cos(180/n),
		r = get_radius(r1=ir*sc, r=or, d1=id*sc, d=od, dflt=side/2/sin(180/n)),
		offset = 90 + (realign? (180/n) : 0),
		path = [for (a=[0:360/n:360-EPSILON]) r*[cos(a+offset),sin(a+offset)]]
	) rot(spin, p=move(-r*normalize(anchor), p=path));


module regular_ngon(n=6, or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0)
	polygon(regular_ngon(n=n,or=or,od=od,ir=ir,id=id,side=side,realign=realign, anchor=anchor, spin=spin));


// Function&Module: pentagon()
// Usage:
//   pentagon(or|od, [realign]);
//   pentagon(ir|id, [realign];
//   pentagon(side, [realign];
// Description:
//   When called as a function, returns a 2D path for a regular pentagon.
//   When called as a module, creates a 2D regular pentagon.
// Arguments:
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   pentagon(or=30);
//   pentagon(od=60);
// Example(2D): by Inner Size
//   pentagon(ir=30);
//   pentagon(id=60);
// Example(2D): by Side Length
//   pentagon(side=20);
// Example(2D): Realigned
//   pentagon(side=20, realign=true);
// Example(2D): Called as Function
//   stroke(closed=true, pentagon(or=30));
function pentagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0) =
	regular_ngon(n=5, or=or, od=od, ir=ir, id=id, side=side, realign=realign, anchor=anchor, spin=spin);


module pentagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0)
	polygon(pentagon(or=or, od=od, ir=ir, id=id, side=side, realign=realign, anchor=anchor, spin=spin));


// Function&Module: hexagon()
// Usage:
//   hexagon(or, od, ir, id, side);
// Description:
//   When called as a function, returns a 2D path for a regular hexagon.
//   When called as a module, creates a 2D regular hexagon.
// Arguments:
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   hexagon(or=30);
//   hexagon(od=60);
// Example(2D): by Inner Size
//   hexagon(ir=30);
//   hexagon(id=60);
// Example(2D): by Side Length
//   hexagon(side=20);
// Example(2D): Realigned
//   hexagon(side=20, realign=true);
// Example(2D): Called as Function
//   stroke(closed=true, hexagon(or=30));
function hexagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0) =
	regular_ngon(n=6, or=or, od=od, ir=ir, id=id, side=side, realign=realign, anchor=anchor, spin=spin);


module hexagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0)
	polygon(hexagon(or=or, od=od, ir=ir, id=id, side=side, realign=realign, anchor=anchor, spin=spin));


// Function&Module: octagon()
// Usage:
//   octagon(or, od, ir, id, side);
// Description:
//   When called as a function, returns a 2D path for a regular octagon.
//   When called as a module, creates a 2D regular octagon.
// Arguments:
//   or = Outside radius, at points.
//   od = Outside diameter, at points.
//   ir = Inside radius, at center of sides.
//   id = Inside diameter, at center of sides.
//   side = Length of each side.
//   realign = If false, a tip is aligned with the Y+ axis.  If true, the midpoint of a side is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D): by Outer Size
//   octagon(or=30);
//   octagon(od=60);
// Example(2D): by Inner Size
//   octagon(ir=30);
//   octagon(id=60);
// Example(2D): by Side Length
//   octagon(side=20);
// Example(2D): Realigned
//   octagon(side=20, realign=true);
// Example(2D): Called as Function
//   stroke(closed=true, octagon(or=30));
function octagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0) =
	regular_ngon(n=8, or=or, od=od, ir=ir, id=id, side=side, realign=realign, anchor=anchor, spin=spin);


module octagon(or=undef, od=undef, ir=undef, id=undef, side=undef, realign=false, anchor=CENTER, spin=0)
	polygon(octagon(or=or, od=od, ir=ir, id=id, side=side, realign=realign, anchor=anchor, spin=spin));


// Function&Module: glued_circles()
// Usage:
//   glued_circles(r|d, spread, tangent);
// Description:
//   When called as a function, returns a 2D path forming a shape of two circles joined by curved waist.
//   When called as a module, creates a 2D shape of two circles joined by curved waist.
// Arguments:
//   r = The radius of the end circles.
//   d = The diameter of the end circles.
//   spread = The distance between the centers of the end circles.
//   tangent = The angle in degrees of the tangent point for the joining arcs, measured away from the Y axis.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   glued_circles(r=15, spread=40, tangent=45);
//   glued_circles(d=30, spread=30, tangent=30);
//   glued_circles(d=30, spread=30, tangent=15);
//   glued_circles(d=30, spread=30, tangent=-30);
// Example(2D): Called as Function
//   stroke(closed=true, glued_circles(r=15, spread=40, tangent=45));
function glued_circles(r=undef, d=undef, spread=10, tangent=30, anchor=CENTER, spin=0) =
	let(
		r = get_radius(r=r, d=d, dflt=10),
		r2 = (spread/2 / sin(tangent)) - r,
		cp1 = [spread/2, 0],
		cp2 = [0, (r+r2)*cos(tangent)],
		sa1 = 90-tangent,
		ea1 = 270+tangent,
		lobearc = ea1-sa1,
		lobesegs = floor(segs(r)*lobearc/360),
		lobestep = lobearc / lobesegs,
		sa2 = 270-tangent,
		ea2 = 270+tangent,
		subarc = ea2-sa2,
		arcsegs = ceil(segs(r2)*abs(subarc)/360),
		arcstep = subarc / arcsegs,
		s = [spread/2+r, r],
		path = concat(
			[for (i=[0:1:lobesegs]) let(a=sa1+i*lobestep)     r  * [cos(a),sin(a)] - cp1],
			tangent==0? [] : [for (i=[0:1:arcsegs])  let(a=ea2-i*arcstep+180)  r2 * [cos(a),sin(a)] - cp2],
			[for (i=[0:1:lobesegs]) let(a=sa1+i*lobestep+180) r  * [cos(a),sin(a)] + cp1],
			tangent==0? [] : [for (i=[0:1:arcsegs])  let(a=ea2-i*arcstep)      r2 * [cos(a),sin(a)] + cp2]
		)
	) rot(spin, p=move(-vmul(anchor,s), p=path));


module glued_circles(r=undef, d=undef, spread=10, tangent=30, anchor=CENTER, spin=0)
	polygon(glued_circles(r=r, d=d, spread=spread, tangent=tangent, anchor=anchor, spin=spin));


// Function&Module: star()
// Usage:
//   star(n, r|d, ir|id|step, [realign]);
// Description:
//   When called as a function, returns the path needed to create a star polygon with N points.
//   When called as a module, creates a star polygon with N points.
// Arguments:
//   n = The number of stellate tips on the star.
//   r = The radius to the tips of the star.
//   d = The diameter to the tips of the star.
//   ir = The radius to the inner corners of the star.
//   id = The diameter to the inner corners of the star.
//   step = Calculates the radius of the inner star corners by virtually drawing a straight line `step` tips around the star.  2 <= step < n/2
//   realign = If false, a tip is aligned with the Y+ axis.  If true, an inner corner is aligned with the Y+ axis.  Default: false
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Examples(2D):
//   star(n=5, r=50, ir=25);
//   star(n=5, r=50, step=2);
//   star(n=7, r=50, step=2);
//   star(n=7, r=50, step=3);
// Example(2D): Realigned
//   star(n=7, r=50, step=3, realign=true);
// Example(2D): Called as Function
//   stroke(closed=true, star(n=5, r=50, ir=25));
function star(n, r, d, ir, id, step, realign=false, anchor=CENTER, spin=0) =
	let(
		r = get_radius(r=r, d=d),
		count = num_defined([ir,id,step]),
		stepOK = is_undef(step) || (step>1 && step<n/2)
	)
	assert(count==1, "Must specify exactly one of ir, id, step")
	assert(stepOK, str("Parameter 'step' must be between 2 and ",floor(n/2)," for ",n," point star"))
	let(
		stepr = is_undef(step)? r : r*cos(180*step/n)/cos(180*(step-1)/n),
		ir = get_radius(r=ir, d=id, dflt=stepr),
		offset = 90+(realign? 180/n : 0),
		path = [for(i=[0:1:2*n-1]) let(theta=180*i/n+offset, radius=(i%2)?ir:r) radius*[cos(theta), sin(theta)]]
	) rot(spin, p=move(-r*normalize(anchor), p=path));


module star(n, r, d, ir, id, step, realign=false, anchor=CENTER, spin=0)
	polygon(star(n=n, r=r, d=d, ir=ir, id=id, step=step, realign=realign, anchor=anchor, spin=spin));


function _superformula(theta,m1,m2,n1,n2=1,n3=1,a=1,b=1) =
	pow(pow(abs(cos(m1*theta/4)/a),n2)+pow(abs(sin(m2*theta/4)/b),n3),-1/n1);

// Function&Module: supershape()
// Usage:
//   supershape(step,[m1],[m2],[n1],[n2],[n3],[a],[b],[r|d]);
// Description:
//   When called as a function, returns a 2D path for the outline of the [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
//   When called as a module, creates a 2D [Superformula](https://en.wikipedia.org/wiki/Superformula) shape.
// Arguments:
//   step = The angle step size for sampling the superformula shape.  Smaller steps are slower but more accurate.
//   m1 = The m1 argument for the superformula. Default: 4.
//   m2 = The m2 argument for the superformula. Default: m1.
//   n1 = The n1 argument for the superformula. Default: 1.
//   n2 = The n2 argument for the superformula. Default: n1.
//   n3 = The n3 argument for the superformula. Default: n2.
//   a = The a argument for the superformula.  Default: 1.
//   b = The b argument for the superformula.  Default: a.
//   r = Radius of the shape.  Scale shape to fit in a circle of radius r.
//   d = Diameter of the shape.  Scale shape to fit in a circle of diameter d.
//   anchor = Translate so anchor point is at origin (0,0,0).  See [anchor](attachments.scad#anchor).  Default: `CENTER`
//   spin = Rotate this many degrees around the Z axis after anchor.  See [spin](attachments.scad#spin).  Default: `0`
// Example(2D):
//   supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,r=50);
// Example(2D): Called as Function
//   stroke(closed=true, supershape(step=0.5,m1=16,m2=16,n1=0.5,n2=0.5,n3=16,d=100));
// Examples(2D,Med):
//   for(n=[2:5]) right(2.5*(n-2)) supershape(m1=4,m2=4,n1=n,a=1,b=2);  // Superellipses
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(.5,m1=m[i],n1=1);
//   m=[6,8,10,12]; for(i=[0:3]) right(2.7*i) supershape(.5,m1=m[i],n1=1,b=1.5);  // m should be even
//   m=[1,2,3,5]; for(i=[0:3]) fwd(1.5*i) supershape(m1=m[i],n1=0.4);
//   supershape(m1=5, n1=4, n2=1); right(2.5) supershape(m1=5, n1=40, n2=10);
//   m=[2,3,5,7]; for(i=[0:3]) right(2.5*i) supershape(m1=m[i], n1=60, n2=55, n3=30);
//   n=[0.5,0.2,0.1,0.02]; for(i=[0:3]) right(2.5*i) supershape(m1=5,n1=n[i], n2=1.7);
//   supershape(m1=2, n1=1, n2=4, n3=8);
//   supershape(m1=7, n1=2, n2=8, n3=4);
//   supershape(m1=7, n1=3, n2=4, n3=17);
//   supershape(m1=4, n1=1/2, n2=1/2, n3=4);
//   supershape(m1=4, n1=4.0,n2=16, n3=1.5, a=0.9, b=9);
//   for(i=[1:4]) right(3*i) supershape(m1=i, m2=3*i, n1=2);
//   m=[4,6,10]; for(i=[0:2]) right(i*5) supershape(m1=m[i], n1=12, n2=8, n3=5, a=2.7);
//   for(i=[-1.5:3:1.5]) right(i*1.5) supershape(m1=2,m2=10,n1=i,n2=1);
//   for(i=[1:3],j=[-1,1]) translate([3.5*i,1.5*j])supershape(m1=4,m2=6,n1=i*j,n2=1);
//   for(i=[1:3]) right(2.5*i)supershape(step=.5,m1=88, m2=64, n1=-i*i,n2=1,r=1);
function supershape(step=0.5,m1=4,m2=undef,n1=1,n2=undef,n3=undef,a=1,b=undef,r=undef,d=undef,anchor=CENTER, spin=0) =
	let(
		r = get_radius(r=r,d=d,dflt=undef),
		m2 = is_def(m2) ? m2 : m1,
		n2 = is_def(n2) ? n2 : n1,
		n3 = is_def(n3) ? n3 : n2,
		b = is_def(b) ? b : a,
		steps = ceil(360/step),
		step = 360/steps,
		angs = [for (i = [0:steps-1]) step*i],
		rads = [for (theta = angs) _superformula(theta=theta,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b)],
		scale = is_def(r) ? r/max(rads) : 1,
		path = [for (i = [0:steps-1]) let(a=angs[i]) scale*rads[i]*[cos(a), sin(a)]]
	) rot(spin, p=move(-scale*max(rads)*normalize(anchor), p=path));

module supershape(step=0.5,m1=4,m2=undef,n1,n2=undef,n3=undef,a=1,b=undef, r=undef, d=undef, anchor=CENTER, spin=0)
	polygon(supershape(step=step,m1=m1,m2=m2,n1=n1,n2=n2,n3=n3,a=a,b=b, r=r,d=d, anchor=anchor, spin=spin));


// Function: turtle()
// Usage:
//   turtle(commands, [state], [return_state])
// Description:
//   Use a sequence of turtle graphics commands to generate a path.  The parameter `commands` is a list of
//   turtle commands and optional parameters for each command.  The turtle state has a position, movement direction,
//   movement distance, and default turn angle.  If you do not give `state` as input then the turtle starts at the
//   origin, pointed along the positive x axis with a movement distance of 1.  By default, `turtle` returns just
//   the computed turtle path.  If you set `full_state` to true then it instead returns the full turtle state.
//   You can invoke `turtle` again with this full state to continue the turtle path where you left off.
//   
//   For the list below, `dist` is the current movement distance.
//   
//   Turtle commands:
//   - "move", [scale]: Move turtle scale*dist units in the turtle direction.  Default scale=1.
//   - "xmove", [scale]: Move turtle scale*dist units in the x direction. Default scale=1.
//   - "ymove", [scale]: Move turtle scale*dist units in the y direction. Default scale=1.
//   - "untilx", xtarget: Move turtle in turtle direction until x==xtarget.  Produces an error if xtarget is not reachable.
//   - "untily", ytarget: Move turtle in turtle direction until y==ytarget.  Produces an error if xtarget is not reachable.
//   - "jump", point: Move the turtle to the specified point
//   - "xjump", x: Move the turtle's x position to the specified value
//   - "yjump, y: Move the turtle's y position to the specified value
//   - "turn", [angle]: Turn turtle direction by specified angle, or the turtle's default turn angle.  The default angle starts at 90.
//   - "left", [angle]: Same as "turn"
//   - "right", [angle]: Same as "turn", -angle
//   - "angle", angle: Set the default turn angle.
//   - "setdir", dir: Set turtle direction.  The parameter `dir` can be an angle or a vector.
//   - "length", length: Change the turtle move distance to `length`
//   - "scale", factor: Multiply turtle move distance by `factor`
//   - "addlength", length: Add `length` to the turtle move distance
//   - "repeat", count, comands: Repeats a list of commands `count` times.  
//
// Arguments:
//   commands = list of turtle commands
//   state = starting turtle state (from previous call) or starting point.  Default: start at the origin
//   full_state = if true return the full turtle state for continuing the path in subsequent turtle calls.  Default: false
//   repeat = number of times to repeat the command list.  Default: 1
//
// Example(2D): Simple rectangle
//   path = turtle(["xmove",3, "ymove", "xmove",-3, "ymove",-1]);
//   stroke(path,width=.1);
// Example(2D): Pentagon
//   path=turtle(["angle",360/5,"move","turn","move","turn","move","turn","move"]);
//   stroke(path,width=.1,closed=true);
// Example(2D): Pentagon using the repeat argument
//   path=turtle(["move","turn",360/5],repeat=5);
//   stroke(path,width=.1,closed=true);
// Example(2D): Pentagon using the repeat turtle command, setting the turn angle
//   path=turtle(["angle",360/5,"repeat",5,["move","turn"]]);
//   stroke(path,width=.1,closed=true);
// Example(2D): Pentagram
//   path = turtle(["move","left",144], repeat=10);
//   stroke(path,width=.05);
// Example(2D): Sawtooth path
//   path = turtle([
//       "turn", 55,
//       "untily", 2,
//       "turn", -55-90,
//       "untily", 0,
//       "turn", 55+90,
//       "untily", 2.5,
//       "turn", -55-90,
//       "untily", 0,
//       "turn", 55+90,
//       "untily", 3,
//       "turn", -55-90,
//       "untily", 0
//   ]);
//   stroke(path, width=.1);
// Example(2D): Simpler way to draw the sawtooth.  The direction of the turtle is preserved when executing "yjump".
//   path = turtle([
//       "turn", 55,
//       "untily", 2,
//       "yjump", 0,
//       "untily", 2.5,
//       "yjump", 0,
//       "untily", 3,
//       "yjump", 0,
//   ]);
//   stroke(path, width=.1);
// Example(2DMed): square spiral
//   path = turtle(["move","left","addlength",1],repeat=50);
//   stroke(path,width=.2);
// Example(2DMed): pentagonal spiral
//   path = turtle(["move","left",360/5,"addlength",1],repeat=50);
//   stroke(path,width=.2);
// Example(2DMed): yet another spiral, without using `repeat`
//   path = turtle(concat(["angle",71],flatten(replist(["move","left","addlength",1],50))));
//   stroke(path,width=.2);
// Example(2DMed): The previous spiral grows linearly and eventually intersects itself.  This one grows geometrically and does not.
//   path = turtle(["move","left",71,"scale",1.05],repeat=50);
//   stroke(path,width=.05);
// Example(2D): Koch Snowflake
//   function koch_unit(depth) =
//       depth==0 ? ["move"] :
//       concat(
//           koch_unit(depth-1),
//           ["right"],
//           koch_unit(depth-1),
//           ["left","left"],
//           koch_unit(depth-1),
//           ["right"],
//           koch_unit(depth-1)
//       );
//   koch=concat(["angle",60,"repeat",3],[concat(koch_unit(3),["left","left"])]);
//   polygon(turtle(koch));
function turtle(commands, state=[[[0,0]],[1,0],90], full_state=false, repeat=1) =
	let( state = is_vector(state) ? [[state],[1,0],90] : state )
        repeat == 1 ? _turtle(commands,state,full_state) 
                    : _turtle_repeat(commands, state, full_state, repeat);

function _turtle_repeat(commands, state, full_state, repeat) =
       repeat==1 ? _turtle(commands,state,full_state)
                 : _turtle_repeat(commands, _turtle(commands, state, true), full_state, repeat-1);
                 

function _turtle_command_len(commands, index) =
         commands[index] == "repeat" ? 3 :   // Repeat command requires 2 args
         is_string(commands[index+1]) ? 1    // If 2nd item is a string it's must be a new command
         : 2;                                  // Otherwise we have command and arg

function _turtle(commands, state, full_state, index=0) =
	index < len(commands) ?
		_turtle(commands,
			_turtle_command(commands[index],commands[index+1],commands[index+2],state,index),
			full_state,
			index+_turtle_command_len(commands,index)
		) :
		( full_state ? state : state[0] );

// Turtle state: state = [path, step_vector, default angle]

function _turtle_command(command, parm, parm2, state, index) =
        command == "repeat" ? assert(is_num(parm),str("\"repeat\" command requires a numeric parameter at index ",index))
                              assert(is_list(parm2),str("\"repeat\" command requires a command list parameter at index ",index))
                              _turtle_repeat(parm2, state, true, parm)
        :
	let(
		path = 0,
		step=1,
		angle=2,
		parm = !is_string(parm) ? parm : undef,
		needvec = ["jump"],
		neednum = ["untilx","untily","xjump","yjump","angle","length","scale","addlength"],
		needeither = ["setdir"],
		chvec = !in_list(command,needvec) || is_vector(parm),
		chnum = !in_list(command,neednum) || is_num(parm),
		vec_or_num = !in_list(command,needeither) || (is_num(parm) || is_vector(parm)),
		lastpt = select(state[path],-1)
	)
	assert(chvec,str("\"",command,"\" requires a vector parameter at index ",index))
	assert(chnum,str("\"",command,"\" requires a numeric parameter at index ",index))
	assert(vec_or_num,str("\"",command,"\" requires a vector or numeric parameter at index ",index))

	command=="move" ? list_set(state, path, concat(state[path],[default(parm,1)*state[step]+lastpt])) :
	command=="untilx" ? (
		let(
			int = line_intersection([lastpt,lastpt+state[step]], [[parm,0],[parm,1]]),
			xgood = sign(state[step].x) == sign(int.x-lastpt.x)
		)
		assert(xgood,str("\"untilx\" never reaches desired goal at index ",index))
		list_set(state,path,concat(state[path],[int]))
	) :
	command=="untily" ? (
		let(
			int = line_intersection([lastpt,lastpt+state[step]], [[0,parm],[1,parm]]),
			ffd=echo(int=int),
			ygood = is_def(int) && sign(state[step].y) == sign(int.y-lastpt.y)
		)
		assert(ygood,str("\"untily\" never reaches desired goal at index ",index))
		list_set(state,path,concat(state[path],[int]))
	) :
	command=="xmove" ? list_set(state, path, concat(state[path],[default(parm,1)*norm(state[step])*[1,0]+lastpt])):
	command=="ymove" ? list_set(state, path, concat(state[path],[default(parm,1)*norm(state[step])*[0,1]+lastpt])):
	command=="jump" ?  list_set(state, path, concat(state[path],[parm])):
	command=="xjump" ? list_set(state, path, concat(state[path],[[parm,lastpt.y]])):
	command=="yjump" ? list_set(state, path, concat(state[path],[[lastpt.x,parm]])):
	command=="turn" || command=="left" ? list_set(state, step, rot(default(parm,state[angle]),p=state[step],planar=true)) :
	command=="right" ? list_set(state, step, rot(-default(parm,state[angle]),p=state[step],planar=true)) :
	command=="angle" ? list_set(state, angle, parm) :
	command=="setdir" ? (
		is_vector(parm) ?
			list_set(state, step, norm(state[step]) * normalize(parm)) :
			list_set(state, step, norm(state[step]) * [cos(parm),sin(parm)])
	) :
	command=="length" ? list_set(state, step, parm*normalize(state[step])) :
	command=="scale" ?  list_set(state, step, parm*state[step]) :
	command=="addlength" ?  list_set(state, step, state[step]+normalize(state[step])*parm) :
	assert(false,str("Unknown turtle command \"",command,"\" at index",index))
	[];


// vim: noexpandtab tabstop=4 shiftwidth=4 softtabstop=4 nowrap
