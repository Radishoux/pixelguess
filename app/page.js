import React from 'react'
var axios = require('axios');

function PixlImg() {
  return (
    <img
      id="pixlImg"
      alt="Pixl logo"
      src="https://mario.wiki.gallery/images/thumb/3/3e/MPSS_Mario.png/800px-MPSS_Mario.png"
      width={500}
      height={500}
    />
  )
}

export default function Home() {
  return (
    <div>
      <PixlImg />
      <div></div>
    </div>
  )
}

