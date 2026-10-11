extension LanguageProfile {
    /// Measured on macOS's Webster's Second (`/usr/share/dict/words`), its 210,773 lowercase
    /// entries. Inside a word, a pair counts as impossible when at most five entries contain
    /// it, all obscure loanwords ("calfkill", "foujdar"). As a start, only when no entry
    /// begins with it, so real words such as "if" never trip it. Regenerate the same way;
    /// never edit by hand.
    package static let english = LanguageProfile(
        language: .english,
        impossiblePairs: [
            "bx bz",
            "cf cg cj cv cx",
            "dx",
            "fj fk fq fv fx fz",
            "gj gq gv gx",
            "hj hq hx hz",
            "jb jc jd jf jg jh jj jk jl jm jn jp jq js jt jv jw jx jy jz",
            "kq kv kx kz",
            "lj lx",
            "mq mx mz",
            "pq pv px pz",
            "qa qb qc qd qe qf qg qh qi qj qk ql qm qn qo qp qq qr qs qt qv qw qx qy qz",
            "rx",
            "sx",
            "tx",
            "vb vc vd vf vg vh vj vk vl vm vn vp vq vs vt vw vx vz",
            "wj wq wv wx",
            "xj xk xv xx xz",
            "yj yq yy",
            "zc zd zf zh zj zk zm zn zp zq zr zs zv zx",
        ],
        impossibleStarts: [
            "bb bc bf bg bj bk bm bn bp bq bs bt bv bw bx bz",
            "cb cc cd cf cg cj ck cm cp cq cv cx",
            "db dc dd df dg dk dl dm dn dp dq ds dt dx",
            "fb fc fd ff fg fh fk fm fn fp fq fs ft fv fw fx fz",
            "gb gc gd gf gg gj gk gp gq gs gt gv gx gz",
            "hb hc hd hf hg hh hj hk hl hm hn hp hq hr hs ht hv hw hx hz",
            "iq iu",
            "jb jc jd jf jg jj jk jl jm jn jp jq jr js jt jv jw jx jz",
            "kb kc kd kf kg kk kp kq ks kt kx kz",
            "lb lc ld lf lg lj lk lm ln lp lq lr ls lt lv lw lx lz",
            "mc md mf mg mj mk mm mq mr ms mt mv mw mx mz",
            "nb nc nd nf nh nk nl nm nn np nq nr ns nv nw nx nz",
            "oj",
            "pb pc pd pg pj pk pm pp pq pv pw px pz",
            "qb qc qd qf qg qh qj qk ql qm qn qp qq qr qs qt qv qw qx qy qz",
            "rb rc rd rf rg rj rk rl rm rn rp rq rr rs rt rw rx rz",
            "sx",
            "tb td tf tg tk tn tp tq tt tv tx",
            "ue uf uo uq uu uw uy",
            "vb vc vd vf vg vh vj vk vm vn vp vq vs vt vv vw vx vz",
            "wb wc wd wf wg wj wk wm wn wp wq ws wt wv ww wx wz",
            "xb xc xd xf xg xh xj xk xl xm xn xp xq xr xs xt xv xw xx xz",
            "yb yf yh yj yk yl yq ys yv yw yx yy yz",
            "zb zc zd zf zg zh zj zk zm zn zp zq zr zs zt zv zx zz",
        ]
    )
}
