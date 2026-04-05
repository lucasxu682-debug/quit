import asyncio
import json
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
            viewport={'width': 1707, 'height': 1067},
            locale='zh-CN'
        )
        
        # More complete cookies
        cookies_text = """s_v_web_id=verify_mmmg8cxh_0VuZw8Db_B5JI_4YoD_9Mcg_uRIogKbBVPrZ; passport_csrf_token=68e1fffc54425bb379bd8aab3b551ee1; login_time=1775192233883; IsDouyinActive=true; UIFID=99405022e0708801aee7ff4c54400ac8e593ae85f3b433b0b452508931dcf94ff4e1625228faea179fad600f45c0cd84a48e218a88917f00426c06f03834cde8c0574d9ec86389efc04d953a0cd9c4d3185ae3546ef916b502e2a481149ff386206406691fc1537926532021135cd6d208aae1867c188db64153c7dd499b0e5ace4d42e3965ebe2ed379462c2f8a1fa813a75a03ed039cf48fa124386f07be9d; __ac_signature=_02B4Z6wo00f01bX9xvQAAIDBO7CwwwazEV213cJAAATP1f; bd_ticket_guard_client_data_v2=eyJyZWVfcHVibGljX2tleSI6IkJJbnZ1ekpjQUhsazREZlV2aTF2R3BKaWdYMDBPSnBoTXNVMm9LTnI5Q3lFOGFJL2dXUWYzZloxcWJvaFI4UVBZblZoYlVTeEFPU1E3eXB0L0N2eXlROD0iLCJ0c19zaWduIjoidHMuMi42NDkxZWY4MDIzN2RlNTA3YzE4MjFkZGZjZTNmMTk1MGY1MTYzMTJkMmRlMTUxZDIwZWJjYTU0OTA4ODA2Y2Y5YzRmYmU4N2QyMzE5Y2YwNTMxODYyNGNlZGExNDkxMWNhNDA2ZGVkYmViZWRkYjJlMzBmY2U4ZDRmYTAyNTc1ZCIsInJlcV9jb250ZW50Ijoic2VjX3RzIiwicmVxX3NpZ24iOiJsQ21UaFl1L3VrOVh5TEQyTGVwZDBIdGZ2RXZScGdkRnd1TkFyblFvWnNBPSIsInNlY190cyI6IiNOR0VuMzliSDJUcE9mMFB6enRDOE9GanBuU1dCbkNDMXNKL3FBNVhEVVVVNkVPbkxaK3F1OTVBUVFDK0sifQ=="""
        
        # Parse and add cookies
        for cookie_str in cookies_text.split(';'):
            cookie_str = cookie_str.strip()
            if '=' in cookie_str:
                name, value = cookie_str.split('=', 1)
                try:
                    await context.add_cookies([
                        {'name': name.strip(), 'value': value.strip(), 'domain': '.douyin.com', 'path': '/'}
                    ])
                except:
                    pass
        
        page = await context.new_page()
        
        print('Navigating...')
        response = await page.goto('https://www.douyin.com/video/7623877586552147251', timeout=30000)
        print(f'Status: {response.status}')
        
        # Wait for dynamic content
        await page.wait_for_timeout(8000)
        
        # Get video data from page
        data = await page.evaluate('''() => {
            // Look for script tags with data
            const scripts = document.querySelectorAll('script');
            let data = null;
            for (let s of scripts) {
                if (s.textContent && s.textContent.includes('RENDER_DATA')) {
                    data = s.textContent;
                    break;
                }
            }
            return {
                hasVideo: !!document.querySelector('video'),
                videoCount: document.querySelectorAll('video').length,
                scriptCount: scripts.length,
                hasData: !!data,
                dataLength: data ? data.length : 0,
                url: window.location.href
            };
        }''')
        
        print('Page data:', json.dumps(data, indent=2))
        
        # Try to get the video element
        video_info = await page.evaluate('''() => {
            const video = document.querySelector('video');
            if (video) {
                return {
                    src: video.src,
                    currentSrc: video.currentSrc,
                    readyState: video.readyState
                };
            }
            return null;
        }''')
        
        print('Video info:', video_info)
        
        await browser.close()
        print('Done')

asyncio.run(main())
