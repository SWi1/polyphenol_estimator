---
layout: default
title: Contact
nav_order: 6
---

<h2>Contact Us</h2>

<p>Have a question or want to provide feedback on Polyphenol Estimator? Use the form below to get in touch, or create an issue on GitHub (<a href="https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/creating-an-issue">more</a>).</p>


<style>
  form {
    max-width: 500px;
  }
  form label {
    display: block;
    margin-bottom: 10px;
  }
  form input[type="text"],
  form input[type="email"],
  form textarea {
    width: 100%;
    box-sizing: border-box;
    padding: 8px;
    font-size: 1em;
  }
  form textarea {
    resize: none; /* prevent dragging to resize */
    height: 150px;
  }
  form button {
    padding: 8px 16px;
    font-size: 1em;
    cursor: pointer;
  }
</style>

<form action="https://formspree.io/f/xeodabjk" method="POST">
  <label>
    Your Name:
    <input type="text" name="name" required>
  </label>

  <label>
    Your Email:
    <input type="email" name="_replyto" required>
  </label>

  <label>
    Message:
    <textarea name="message" required></textarea>
  </label>

  <button type="submit">Send</button>
</form>